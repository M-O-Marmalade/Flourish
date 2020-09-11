--Flourish - main.lua--
--DEBUG CONTROLS-------------------------------
local debug_mode = false 

if debug_mode then
  _AUTO_RELOAD_DEBUG = true
end

local auto_apply = true 

local flourishtotalclock 

local clock1 
local clock2 
local clock3 
local clock4 
local clock3a
local clock3b
local clock3c
local clock3d

local clocktemp
local clocktempa
local clocktempb
local clocktempc
local clocktempd 


--GLOBALS-------------------------------------------------------------------------------------------- 
local app = renoise.app() 
local song = nil 
local sequence_index = 0 
local pattern_index = 0 
local track_index = 0 
local track_type = nil 
local line_index = 0 

local time = 0 
local time_max = 2100
local time_multiplier = 1 
local time_multiplier_max = 64
local tension = 1 
local tension_max = 0.999
local time_offset = 0 
local time_offset_max = 3200
local time_offset_multiplier = 1 
local time_offset_multiplier_max = 64
local destructive = false 

local cur_lin_ref = nil 
local cur_lin_clmn_vals = {} 
local notes_detected = 0 

local pats_to_clear = {} 
local lins_to_clear = {} 
local column_vals_to_store = {} 
local column_pats_to_store = {} 
local column_lins_to_store = {} 
local is_first_flourish = true
local have_valid_line = false

local start_pos = renoise.SongPos() 

local vb = renoise.ViewBuilder() 
local flourish_window_obj = nil 
local flourish_window_created = nil 
local window_title = nil 
local window_content = nil 
local sliders_width = 22
local sliders_height = 127
local multipliers_size = 23

--SHOW STATUS---------------------------------------------------------------------------------------- 
local function show_status(message) 
  app:show_status(message) 
  print(message) 
end 

--CLEAR COLUMNS_TO_CLEAR----------------------------------------------------------------------------- 
local function clear_columns_to_clear() 
  if debug_mode then print("CLEAR_COLUMNS_TO_CLEAR()") end 
  for i = 1, 12 do 
    pats_to_clear[i] = pattern_index 
    lins_to_clear[i] = line_index 
    column_pats_to_store[i] = pattern_index 
    column_lins_to_store[i] = line_index 
    column_vals_to_store[i] = {} 
    for j = 1, 7 do 
      column_vals_to_store[i][j] = 0 
    end 
  end 
end 

--GET CURRENT LINE----------------------------------------------------------------------------------- 
local function get_current_line() 
  if debug_mode then print("GET_CURRENT_LINE()") end 
  app = renoise.app() 
  song = renoise.song()   

  track_type = song.selected_track.type--check the type of track that's selected 
  if track_type ~= 1 then --if the track is master or send, show error... 
    app:show_error("Please move edit cursor to a non-Master/Send track! Master/Send tracks are not supported with the Flourish tool.") 
  else --...if the track is a valid track, we... 
    --... store some indexing info in memory... 
    sequence_index = song.selected_sequence_index 
    pattern_index = song.selected_pattern_index 
    track_index = song.selected_track_index 
    line_index = song.selected_line_index 
    cur_lin_ref = song.patterns[pattern_index].tracks[track_index]:line(line_index) 
    start_pos.sequence = sequence_index 
    start_pos.line = line_index 
    clear_columns_to_clear()--...clear our destructive columns clearing index 
    notes_detected = 0 --...reset the amount of detected notes to 0... 
    --...we store the selected line values in cur_lin_clmn_vals.. 
    local x = 1 
    while x < 13 do 
      cur_lin_clmn_vals[x] = { 
        cur_lin_ref:note_column(x).note_value, 
        cur_lin_ref:note_column(x).instrument_value, 
        cur_lin_ref:note_column(x).volume_value, 
        cur_lin_ref:note_column(x).panning_value, 
        cur_lin_ref:note_column(x).delay_value, 
        cur_lin_ref:note_column(x).effect_number_value, 
        cur_lin_ref:note_column(x).effect_amount_value 
      } 
      x = x + 1 
    end 
--[[ 
    if debug_mode then print("cur_lin_ref: ") print(cur_lin_ref) end 
--]] 
    --...we detect the amount of note columns in the track that have notes... 
    for i = 1, 12 do 
      if not cur_lin_ref:note_column(i).is_empty then notes_detected = i end 
    end 
    --...show the delay columns for the selected track... 
    song.tracks[track_index].delay_column_visible = true 
    --...and confirm the new line selection to the user in the status bar 
    show_status(notes_detected .. " Note Columns selected on Line " .. line_index - 1 .. " in Sequence " .. sequence_index - 1 .. " for Flourish!") 
    if flourish_window_created then --if we have already created a view window... 
      --...reset our sliders to 0 upon setting a new line... 
      vb.views.time_slider.value = 0 
      vb.views.time_multiplier.value = 1 
      vb.views.tension_slider.value = 0 
      vb.views.offset_slider.value = 0 
      vb.views.offset_multiplier.value = 1 
    end 
    time = 0 
    time_multiplier = 1 
    tension = 0
    time_offset = 0 
    time_offset_multiplier = 1 
    
    is_first_flourish = true
    have_valid_line = true
        
  end--close if statement     
end 

--UPDATE TEXT---------------------------------------------------------------------------------------- 
local function update_text() 
  if debug_mode then print("UPDATE_TEXT()") end 
  vb.views.my_text.text = "[" .. notes_detected .. " Columns]" 
end 

--FLOURISH------------------------------------------------------------------------------------------- 
local function flourish() 
  if have_valid_line then
    if debug_mode then print("FLOURISH()") end 
    if debug_mode then 
      flourishtotalclock = os.clock() 
      clock1 = 0 
      clock2 = 0 
      clock3 = 0 
      clock4 = 0
      clock3a = 0 
      clock3b = 0 
      clock3c = 0 
      clock3d = 0 
      clocktemp = os.clock() 
    end 
    if is_first_flourish then
      --clear the line that we're flourishing 
      song.patterns[pattern_index].tracks[track_index]:line(line_index):clear()
    end
    --calculate our time factor to apply to our notes 
    local tim_factor = time * time_multiplier 
    local tim_offset = time_offset * time_offset_multiplier 
    local tens_factor
    local tens_factor_temp
    local div_factor = 1/(notes_detected - 1)
    
    if debug_mode then
      print("nan test: ", div_factor ~= div_factor)  -- test for nan
      print("inf test: ", not(div_factor > -math.huge and div_factor < math.huge))  -- test for finite
    end
    
    --if div_factor does not pass nan and inf tests, then we set it to 1
    if not(div_factor > -math.huge and div_factor < math.huge) or div_factor ~= div_factor then
      div_factor = 1
    end
    
    if debug_mode then
      print("DIV_FACTOR: ",div_factor)
    end
    
    if time < 0 then
      tens_factor_temp = -tension
    elseif time >= 0 then
      tens_factor_temp = tension
    end
    
    if tens_factor_temp > 0 then
      tens_factor = (tens_factor_temp + 0.1) * 10
    elseif tens_factor_temp < 0 then
      tens_factor = tens_factor_temp + 1
    else tens_factor = 1
    end
    
    if debug_mode then 
    print("tension: ", tension)
    print("time: ", time)
    print("tens_factor: ", tens_factor)
    print("tens_factor_temp: ", tens_factor_temp)
      clock1 = os.clock() - clocktemp 
    end 
    
    local store_pattern_lines = {}
    
    for i = 1, notes_detected do  --for each of the notes detected on the current line... 
      if debug_mode then 
        clocktemp = os.clock()
      end 
      
      local current_sequence_offset = 0
      
      --...find the correct line offset to copy to based on our current time factor 
      local line_index_offset = math.floor((((i - 1) * div_factor)^tens_factor * tim_factor + tim_offset) / 255) 
    
      if debug_mode then 
        clock2 = clock2 + os.clock() - clocktemp 
        clocktemp = os.clock()
        clocktempa = os.clock()
        print("line_index: ",line_index) 
        print("line_index_offset: ",line_index_offset) 
      end
    
      local new_seq_index = sequence_index
      local new_lin_index = line_index
      local new_offset = line_index_offset
      local sequence_total = #song.sequencer.pattern_sequence
    
      if debug_mode then
        clock3a = clock3a + os.clock() - clocktempa
        print("new_offset: ",new_offset)
      end
     
      local foundnew = false 
      while not foundnew do 
      
        if debug_mode then
          clocktempb = os.clock()
          print("entered loop1!!!")
        end
      
        if new_offset > 0 then --if time is positive
          while not foundnew do
          
          local lines_in_this_pattern
          
            --get the amount of lines in the current pattern if we don't know it yet
          if not store_pattern_lines[current_sequence_offset] then
          
              store_pattern_lines[current_sequence_offset] = #song.patterns[song.sequencer:pattern(new_seq_index)].tracks[track_index].lines
              lines_in_this_pattern = store_pattern_lines[current_sequence_offset]
              
              if debug_mode then
                print("GOT LINES IN PATTERN",current_sequence_offset,"!")
              end
          else
          
            lines_in_this_pattern = store_pattern_lines[current_sequence_offset]
            
            if debug_mode then
              print("already had lines in store_pattern_lines[",current_sequence_offset,"]!")
            end
          end
          
          if debug_mode then
            print("MADE IT OUT ALIVE!")
          end
          
            --if our line index plus our offset is greater than the amount of lines in this pattern... 
            if new_lin_index + new_offset > lines_in_this_pattern then 
              new_seq_index = new_seq_index + 1      
              
              current_sequence_offset = current_sequence_offset + 1
              if debug_mode then
                print("SURPASSED LINES IN THIS PATTERN!")
              end
               
              if new_seq_index > sequence_total then --if we reach the end of the sequence, wrap back to beginning
                new_seq_index = 1
              end
               
              new_offset = new_offset - (lines_in_this_pattern - new_lin_index)  --prepare our variables to enter the loop again into the next sequence in the song
              new_lin_index = 0
            
            else -- otherwise, if we are in the correct sequence/pattern, then...
              new_lin_index = new_lin_index + new_offset  --set our line index and break the loop(s)
              foundnew = true
              
              if debug_mode then
                print("FOUND DESIRED LINE!")
              end
            end
          end --end while loop
        
        elseif new_offset < 0 then --if time is negative
          while not foundnew do
            --if our line index plus our offset results in 0 or less... 
            if new_lin_index + new_offset < 1 then 
              new_seq_index = new_seq_index - 1 --go to the previous sequence
              
              current_sequence_offset = current_sequence_offset - 1
            
              if new_seq_index == 0 then  --if we reach past the first sequence in the song, wrap to the last sequence
                 new_seq_index = sequence_total  
              end
            
              new_offset = new_offset + new_lin_index  --set our variables for the next time through the loop for the previous sequence in the song
              
              --get the amount of lines in the current pattern if we don't know it yet
              if not store_pattern_lines[current_sequence_offset] then
                
                store_pattern_lines[current_sequence_offset] = #song.patterns[song.sequencer:pattern(new_seq_index)].tracks[track_index].lines
                new_lin_index = store_pattern_lines[current_sequence_offset]
                
                if debug_mode then
                  print("GOT LINES IN PATTERN",current_sequence_offset,"!")
                end
              else
                new_lin_index = store_pattern_lines[current_sequence_offset]
                
                if debug_mode then
                  print("already had lines in store_pattern_lines[",current_sequence_offset,"]!")
                end
              end
          
            else -- otherwise, if we are in the correct sequence/pattern, then...
              new_lin_index = new_lin_index + new_offset  --set our line index and break the loop(s)
              foundnew = true
            end
          end --end while loop
          
        else --if time == 0
          new_lin_index = new_lin_index + new_offset
          foundnew = true
        end
      
        if debug_mode then
          clock3b = clock3b + os.clock() - clocktempb
        end
      end
    
    
      if debug_mode then 
        clock3 = clock3 + os.clock() - clocktemp
        clocktemp = os.clock()
        print("new_offset: ", new_offset)
        print("new_lin_index: ", new_lin_index)
      end 
    
      --convert sequence index to pattern index 
      local new_pat_index = song.sequencer:pattern(new_seq_index)
    
      --find correct note column reference to copy to 
      local column_to_copy_to = song.patterns[new_pat_index].tracks[track_index]:line(new_lin_index):note_column(i)
      if destructive then --if we are not preserving what we end up flourishing over...
    
        --...clear the columns where we previously moved our notes to 
        song.patterns[pats_to_clear[i]].tracks[track_index]:line(lins_to_clear[i]):note_column(i):clear()
        --...store/update our new columns to clear next time around
        pats_to_clear[i] = new_pat_index
        lins_to_clear[i] = new_lin_index
        
      else --if we are preserving what we end up flourishing over... 
        if not is_first_flourish then
          --get a reference to the column where we previously stored values from 
          local clmn_to_restore_to = song.patterns[column_pats_to_store[i]].tracks[track_index]:line(column_lins_to_store[i]):note_column(i) 
          for j = 1, 7 do --restore all values for the column we are about to leave from 
            clmn_to_restore_to.note_value = column_vals_to_store[i][1] 
            clmn_to_restore_to.instrument_value = column_vals_to_store[i][2] 
            clmn_to_restore_to.volume_value = column_vals_to_store[i][3] 
            clmn_to_restore_to.panning_value = column_vals_to_store[i][4] 
            clmn_to_restore_to.delay_value = column_vals_to_store[i][5] 
            clmn_to_restore_to.effect_number_value = column_vals_to_store[i][6] 
            clmn_to_restore_to.effect_amount_value = column_vals_to_store[i][7] 
          end
        end
        column_pats_to_store[i] = new_pat_index --store the pattern that we will need to restore to later 
        column_lins_to_store[i] = new_lin_index --store the line in that pattern that we will restore to 
        column_vals_to_store[i] = {} --create an empty table to store our values 
        for j = 1, 7 do --store all values for the column we are about to overwrite 
          column_vals_to_store[i][1] = column_to_copy_to.note_value 
          column_vals_to_store[i][2] = column_to_copy_to.instrument_value 
          column_vals_to_store[i][3] = column_to_copy_to.volume_value 
          column_vals_to_store[i][4] = column_to_copy_to.panning_value 
          column_vals_to_store[i][5] = column_to_copy_to.delay_value 
          column_vals_to_store[i][6] = column_to_copy_to.effect_number_value 
          column_vals_to_store[i][7] = column_to_copy_to.effect_amount_value 
        end 
      end 
      --overwrite all values in the column we are flourishing our note into 
      column_to_copy_to.note_value = cur_lin_clmn_vals[i][1] 
      column_to_copy_to.instrument_value = cur_lin_clmn_vals[i][2] 
      column_to_copy_to.volume_value = cur_lin_clmn_vals[i][3] 
      column_to_copy_to.panning_value = cur_lin_clmn_vals[i][4] 
      --column_to_copy_to.delay_value = cur_lin_clmn_vals[i][5] --we dont need the delay value 
      column_to_copy_to.effect_number_value = cur_lin_clmn_vals[i][6] 
      column_to_copy_to.effect_amount_value = cur_lin_clmn_vals[i][7] 
      --new delay value to apply to the new line/note column 
      column_to_copy_to.delay_value = math.floor((((i - 1) * div_factor)^tens_factor * tim_factor + tim_offset) % 255) 
      if time >= 0 then 
        if i == 1 then 
          start_pos.sequence = new_seq_index 
          start_pos.line = new_lin_index 
        end 
      elseif time < 0 then 
        if i == notes_detected then 
          start_pos.sequence = new_seq_index 
          start_pos.line = new_lin_index 
        end 
      end 
    end--for loop close 
    
    is_first_flourish = false
    
    if debug_mode then 
      clock4 = os.clock() - clocktemp 
      flourishtotalclock = os.clock() - flourishtotalclock 
      print("FlourishTotalClock: ", flourishtotalclock) 
      print("Clock1: ", clock1) 
      print("Clock2: ", clock2) 
      print("Clock3: ", clock3) 
      print("clock3a: ", clock3a) 
      print("clock3b: ", clock3b) 
      print("clock3c: ", clock3c) 
      print("clock3d: ", clock3d) 
      print("Clock4: ", clock4)
    
    end 
  end
end 

--CREATE FLOURISH WINDOW----------------------------------------------------------------------------- 
function create_flourish_window() 
  if debug_mode then print("CREATE_FLOURISH_WINDOW()") end 

  window_title = "Flourish" 
  window_content = vb:column { 
    width = 105, 
    vb:row { 
      height = 4 
    }, 

    vb:horizontal_aligner { 
      mode = "center", 
      vb:text {   -- now add the first text into the inner column 
        id = "my_text", 
        style = "normal", 
        font = "bold", 
        text = "[" .. notes_detected .. " Columns]" 
      } 
    }, 
    vb:horizontal_aligner { 
      mode = "distribute", 
      vb:vertical_aligner { 
        mode = "top", 
        vb:bitmap { 
          mode = "body_color", 
          bitmap = "Bitmaps/clock.bmp" 
        }, 
        vb:minislider { 
          id = "time_slider", 
          tooltip = "The time over which to spread the notes", 
          min = -time_max, 
          max = time_max, 
          value = 0, 
          width = sliders_width, 
          height = sliders_height, 
          notifier = function(value) 
            time = -value 
            if debug_mode then show_status(("Time: %.2f"):format(time)) end 
            if auto_apply then flourish() end 
          end 
        } 
      }, 
      vb:vertical_aligner { 
        mode = "top", 
        vb:bitmap { 
          mode = "body_color", 
          bitmap = "Bitmaps/curve.bmp" 
        }, 
        vb:minislider { 
          id = "tension_slider", 
          tooltip = "Distribution of the notes", 
          min = -tension_max, 
          max = tension_max, 
          value = 0, 
          width = sliders_width, 
          height = sliders_height, 
          notifier = function(value) 
            tension = value 
            if debug_mode then show_status(("Tension: %.2f"):format(tension)) end 
            if auto_apply then flourish() end 
          end 
        } 
      },--vertical aligner close 
      vb:vertical_aligner { 
        mode = "top", 
        vb:bitmap { 
          mode = "body_color", 
          bitmap = "Bitmaps/arrows.bmp" 
        }, 
        vb:minislider { 
          id = "offset_slider", 
          tooltip = "Position offset", 
          min = -time_offset_max, 
          max = time_offset_max, 
          value = 0, 
          width = sliders_width, 
          height = sliders_height, 
          notifier = function(value) 
            time_offset = -value 
            if debug_mode then show_status(("Offset: %.2f"):format(time_offset)) end 
            if auto_apply then flourish() end 
          end 
        } 
      }--vertical aligner close 
    },--horizontal aligner close 
    vb:horizontal_aligner { 
      mode = "center", 
              vb:rotary { 
          id = "time_multiplier", 
          tooltip = "Time multiplier", 
          min = 1, 
          max = time_multiplier_max, 
          value = 1, 
          width = multipliers_size, 
          height = multipliers_size, 
          notifier = function(value) 
            time_multiplier = value 
            if auto_apply then flourish() end 
          end 
        }, 
      vb:bitmap { 
        id = "destructive_button", 
        tooltip = "Stilts Dude walks carefully over any notes he finds...\nSteamroller just destroys them!", 
        bitmap = "Bitmaps/stilts.bmp", 
        mode = "body_color", 
        notifier = function() 
          time = 0 
          vb.views.time_slider.value = 0 
          flourish() 
          destructive = not destructive 
          if destructive then vb.views.destructive_button.bitmap = "Bitmaps/steamroller.bmp" 
          else vb.views.destructive_button.bitmap = "Bitmaps/stilts.bmp" end 
        end 
      }, 
      vb:rotary { 
          id = "offset_multiplier", 
          tooltip = "Offset multiplier", 
          min = 1, 
          max = time_offset_multiplier_max, 
          value = 1, 
          width = multipliers_size, 
          height = multipliers_size, 
          notifier = function(value) 
            time_offset_multiplier = value 
            if auto_apply then flourish() end 
          end 
        } 
    },--horizontal aligner close 

    vb:horizontal_aligner { 
      mode = "center", 
      vb:button { 
        text = "Set Line", 
        tooltip = "Set new line to be edited by Flourish", 
        width = "82%", 
        --height = 20, 
        notifier = function() 
          get_current_line() 
          update_text() 
        end 
      }, 
      vb:button { 
        id = "help_button", 
        tooltip = "View instructions", 
        width = 18, 
        height = 18, 
        bitmap = "Bitmaps/question.bmp", 
        notifier = function() 
            app:open_url("https://github.com/M-O-Marmalade/mom.MOMarmalade.Flourish.xrnx") 
        end 
      } 
    }--horizontal aligner close 
  }--window content column close 
  flourish_window_created = true 
end--end function 

--KEY HANDLER FUNCTIONS------------------------------------------------------------------------------ 
local function key_handler(dialog, key) 
  if key.name == "space" then 
    if key.modifiers == "" or key.modifiers == "control" then 
      if key.state == "pressed" then
        if not key.repeated then
          if not song.transport.playing then
            song.transport:start_at(start_pos) 
          end
        end
      elseif key.state == "released" then 
        song.transport:stop() 
      end 
    end 
  end 
  
  if key.name == "z" then  
    if key.modifiers == "control" then    
      if key.state == "pressed" then
        song:undo()
      end
    elseif key.modifiers == "shift + control" then
      if key.state == "pressed" then
        song:redo()
      end
    end
  end
  
  if key.name == "down" then
    if key.modifiers == "" then
      if key.state == "pressed" then        
      
        local edit_pos = song.transport.edit_pos
        local seq_lines = #song.patterns[song.sequencer:pattern(edit_pos.sequence)].tracks[track_index].lines
      
        edit_pos.line = edit_pos.line + 1
      
        if edit_pos.line > seq_lines then
          edit_pos.sequence = edit_pos.sequence + 1
          edit_pos.line = 1
          if edit_pos.sequence > #song.sequencer.pattern_sequence then
            edit_pos.sequence = 1
          end
        end
       
        song.transport.edit_pos = edit_pos
      end
    elseif key.modifiers == "control" then
      if key.state == "pressed" then
        time = time + 1
        if time >= 2100 then
          time = 2100
        end
        vb.views.time_slider.value = -time
      end
    end
  
  elseif key.name == "up" then
    if key.modifiers == "" then
      if key.state == "pressed" then        
      
        local edit_pos = song.transport.edit_pos

      
        edit_pos.line = edit_pos.line - 1
      
        if edit_pos.line < 1 then
          edit_pos.sequence = edit_pos.sequence - 1          
          
          if edit_pos.sequence < 1 then
            edit_pos.sequence = #song.sequencer.pattern_sequence           
          end
          
          edit_pos.line = #song.patterns[song.sequencer:pattern(edit_pos.sequence)].tracks[track_index].lines
          
        end
       
        song.transport.edit_pos = edit_pos
      end
    elseif key.modifiers == "control" then
      if key.state == "pressed" then
        time = time - 1
        if time <= -time_max then
          time = -time_max
        end
        vb.views.time_slider.value = -time
      end
    end
  elseif key.name == "right" then
    if key.modifiers == "" then
      if key.state == "pressed" then        
      
        local edit_track = song.selected_track_index + 1
        local total_tracks = #song.tracks
      
        if edit_track > total_tracks then
          edit_track = 1          
        end
       
        song.selected_track_index = edit_track
      end
    elseif key.modifiers == "control" then
      if key.state == "pressed" then
        time_multiplier = time_multiplier + 1
        if time_multiplier >= time_multiplier_max then
          time_multiplier = time_multiplier_max
        end
        vb.views.time_multiplier.value = time_multiplier
      end
    end
  elseif key.name == "left" then
    if key.modifiers == "" then
      if key.state == "pressed" then        
      
        local edit_track = song.selected_track_index - 1
        local total_tracks = #song.tracks
      
        if edit_track < 1 then
          edit_track = total_tracks         
        end
       
        song.selected_track_index = edit_track
      end
    elseif key.modifiers == "control" then
      if key.state == "pressed" then
        time_multiplier = time_multiplier - 1
        if time_multiplier <= 1 then
          time_multiplier = 1
        end
        vb.views.time_multiplier.value = time_multiplier
      end
    end
  end
  
  if key.name == "x" then
    if key.modifiers == "shift + control" then
      if key.state == "pressed" then
        if key.repeated == false then        
          get_current_line()
          if track_type == 1 then
            update_text()
          end
        end
      end
    end
  end
  
  -- close on escape... 
  if (key.modifiers == "" and key.name == "esc") then 
    dialog:close() 
  end 
end 

--KEY HANDLER OPTIONS-------------------------------------------------------------------------------- 
local key_handler_options = { 
  send_key_repeat = true, 
  send_key_release = true 
} 

--SHOW FLOURISH WINDOW------------------------------------------------------------------------------- 
local function show_flourish_window() 
  if debug_mode then print("SHOW_FLOURISH_WINDOW()") end 
  if not flourish_window_obj or not flourish_window_obj.visible then
    flourish_window_obj = app:show_custom_dialog(window_title, window_content, key_handler, key_handler_options)
  else flourish_window_obj:show()
  end
end

--MAIN FUNCTION-------------------------------------------------------------------------------------- 
local function main_function() 
  if debug_mode then print("MAIN_FUNCTION()") end 
  get_current_line() 
  if track_type == 1 then 
    if not flourish_window_created then create_flourish_window() end 
    update_text() 
    show_flourish_window() 
  end 
end 

--SHOW WINDOW WITHOUT SETTING A NEW NOTE------------------------------------------------------------- 
local function show_window_only() 
  song = renoise.song() 
  if not flourish_window_created then create_flourish_window() end 
  show_flourish_window()
end 

--MENU/HOTKEY ENTRIES-------------------------------------------------------------------------------- 

renoise.tool():add_menu_entry { 
  name = "Main Menu:Tools:Flourish...", 
  invoke = function() main_function() end 
}

renoise.tool():add_menu_entry { 
  name = "Main Menu:Tools:Flourish - Restore Window...", 
  invoke = function() show_window_only() end 
}

renoise.tool():add_menu_entry { 
  name = "Pattern Editor:Flourish...", 
  invoke = function() main_function() end 
}

renoise.tool():add_keybinding { 
  name = "Global:Tools:Flourish...", 
  invoke = function() main_function() end 
}

renoise.tool():add_keybinding { 
  name = "Global:Tools:Flourish - Restore Window...", 
  invoke = function() show_flourish_window() end 
}
