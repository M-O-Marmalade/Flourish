--Flourish - main.lua--
local debug_mode = true
local auto_apply = true
--GLOBALS--------------------------------------------------------------------------------------------
local app = renoise.app()
local song = nil
local sequence_index = 0
local pattern_index = 0
local track_index = 0
local track_type = nil
local line_index = 0

local time = 0
local time_multiplier = 1
local tension = 1
local time_offset = 0
local time_offset_multiplier = 1
local destructive = false

local cur_lin_ref = nil
local cur_lin_clmn_vals = {}
local notes_detected = 0

local pats_to_clear = {}
local lins_to_clear = {}
local column_vals_to_store = {}
local column_pats_to_store = {}
local column_lins_to_store = {}

local start_pos = renoise.SongPos()

local vb = renoise.ViewBuilder() 
local flourish_window_obj = nil
local flourish_window_created = nil
local window_title = nil
local window_content = nil

--SHOW STATUS----------------------------------------------------------------------------------------
local function show_status(message)
  app:show_status(message)
  print(message)
end

--FIND NEW LINE--------------------------------------------------------------------------------------
local function find_new_line(seq, lin, offset)
  if debug_mode then print("FIND_NEW_LINE()") end
  
  --get the amount of lines in the current pattern
  local lines_in_this_pattern = #song.patterns[song.sequencer:pattern(seq)].tracks[track_index].lines
  
  --if our line index plus our offset is greater than the amount of lines in this pattern...
  if lin + offset > lines_in_this_pattern then
    
    local seq_to_pass = seq + 1
    if seq_to_pass > #song.sequencer.pattern_sequence then seq_to_pass = 1 end--wrap from end to beginning
    
    seq,lin = find_new_line(seq_to_pass, 0, offset - (lines_in_this_pattern - lin)) --call next pattern
  
  --if our line index plus our offset results in 0 or less...
  elseif lin + offset < 1 then
    
    local seq_to_pass = seq - 1
    if seq_to_pass == 0 then seq_to_pass = #song.sequencer.pattern_sequence end--wrap beginning to end
    
    seq,lin = find_new_line(seq_to_pass, #song.patterns[song.sequencer:pattern(seq_to_pass)].tracks[track_index].lines, offset + lin) --call function for prev pattern
  
  else
  
    return seq, lin + offset
  
  end  
  
  return seq,lin

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
    
    if debug_mode then print("cur_lin_ref: ") print(cur_lin_ref) end
  
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
      vb.views.offset_multiplier.value = 1
    end
    
    time = 0
    time_multiplier = 1
    tension = 1
    time_offset = 0
    time_offset_multiplier = 1
    
  end--close if statement
end

--UPDATE TEXT----------------------------------------------------------------------------------------
local function update_text()
  if debug_mode then print("UPDATE_TEXT()") end
  vb.views.my_text.text = "[" .. notes_detected .. " Columns]"
end

--FLOURISH-------------------------------------------------------------------------------------------
local function flourish()
  if debug_mode then print("FLOURISH()") end
  
  --clear the line that we're flourishing
  song.patterns[pattern_index].tracks[track_index]:line(line_index):clear()
  
  --calculate our time factor to apply to our notes
  local tim_factor = time * time_multiplier
  local tim_offset = time_offset * time_offset_multiplier
  local div_factor = 1/notes_detected
  local tens_factor = tension
--[[  
  if time < 0 then tens_factor = 10 - tension
  else tens_factor = tension
  end
--]]
  for i = 1, notes_detected do  --for each of the notes detected on the current line...

    --...find the correct line offset to copy to based on our current time factor
    local line_index_offset = math.floor((((i - 1) * div_factor)^tens_factor * tim_factor + tim_offset) / 255)
    
    if debug_mode then 
      print("line_index: ",line_index)
      print("line_index_offset: ",line_index_offset)
    end
    
    --...find correct sequence index, and line index in that sequence, to copy this note to...
    local new_seq_index,new_lin_index = find_new_line(sequence_index,line_index,line_index_offset)
    
    if debug_mode then print("new_lin_index: ", new_lin_index) end
    
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
          min = -2100,
          max = 2100,
          value = 0,
          width = 22,
          height = 127,
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
          tooltip = "(not yet implemented)",
          min = -0.9,
          max = 9,
          value = 0,
          width = 22,
          height = 127,
          notifier = function(value)                           
            tension = 1 + value
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
          tooltip = "Offset the position of the flourish",
          min = -6400,
          max = 6400,
          value = 0,
          width = 22,
          height = 127,
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
          max = 64,
          value = 1,
          width = 23,
          height = 23,
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
          max = 64,
          value = 1,
          width = 23,
          height = 23,
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
            app:open_url("https://github.com/M-O-Marmalade/com.MOMarmalade.Flourish.xrnx")
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
        song.transport:start_at(start_pos)
      elseif key.state == "released" then
        song.transport:stop()
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
  send_key_repeat = false,
  send_key_release = true
}


--SHOW FLOURISH WINDOW-------------------------------------------------------------------------------
local function show_flourish_window()
  if debug_mode then print("SHOW_FLOURISH_WINDOW()") end
  flourish_window_obj = app:show_custom_dialog(window_title, window_content, key_handler, key_handler_options)
end

--MAIN FUNCTION--------------------------------------------------------------------------------------
local function main_function()
  if debug_mode then print("MAIN_FUNCTION()") end
  get_current_line()
  if track_type == 1 then
    if not flourish_window_created then create_flourish_window() end
    update_text()
    if not flourish_window_obj or not flourish_window_obj.visible then show_flourish_window() end
  end
end

--SHOW WINDOW WITHOUT SETTING A NEW NOTE-------------------------------------------------------------
local function show_window_only()
  song = renoise.song()
  if not flourish_window_created then create_flourish_window() end
  if not flourish_window_obj or not flourish_window_obj.visible then show_flourish_window() end
end

--MENU/HOTKEY ENTRIES--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:M.O.Marmalade:Flourish...",
  invoke = function() main_function() end
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:M.O.Marmalade:Flourish - Reveal Window...",
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
  name = "Global:Tools:Flourish - Reveal Window...",
  invoke = function() show_flourish_window() end 
}
