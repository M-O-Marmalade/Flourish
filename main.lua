--Flourish - main.lua--

--GLOBALS--------------------------------------------------------------------------------------------
app = renoise.app()
song = renoise.song()
sequence_size = nil
sequence_index = 0
pattern_amount = nil
pattern_index = 0
track_index = 0
track_type = nil
line_amount = nil
line_index = 0

cur_lin_ref = nil
cur_lin_clmn_vals = {}
lns_in_sng = {}
lns_in_sng_amount = nil
notes_detected = 0

time = 0
tension = 0
auto_apply = true
non_destructive = false
pats_to_clear = {}
lins_to_clear = {}
visible_columns_only = true

local vb = renoise.ViewBuilder() 
flourish_window_obj = nil
flourish_window_created = nil
window_title = nil
window_content = nil

--SHOW STATUS----------------------------------------------------------------------------------------
local function show_status(message)
  app:show_status(message)
  print(message)
end

--FIND NEW LINE--------------------------------------------------------------------------------------
local function find_new_line(seq, lin, offset)
  print("FIND_NEW_LINE()")
  if seq == 0 then seq = #song.sequencer.pattern_sequence --wrap from beginning to end
  elseif seq > #song.sequencer.pattern_sequence then seq = 1 --wrap from end to beginning
  end
  
  --get the amount of lines in the current pattern
  local lines_in_this_pattern = #song.patterns[song.sequencer:pattern(seq)].tracks[track_index].lines
  
  --if our line index plus our offset is greater than the amount of lines in this pattern...
  if lin + offset > lines_in_this_pattern then
    seq,lin = find_new_line(seq+1, 0, offset - (lines_in_this_pattern - lin)) --call function for next pattern
  
  --if our line index plus our offset results in 0 or less...
  elseif lin + offset < 1 then
    seq,lin = find_new_line(seq-1, #song.patterns[song.sequencer:pattern(seq-1)].tracks[track_index].lines, offset + lin) --call function for prev pattern
  
  else
  
    return seq, lin + offset
  
  end  
  
  return seq,lin

end

--CLEAR COLUMNS_TO_CLEAR-----------------------------------------------------------------------------
local function clear_columns_to_clear()
  print("CLEAR_COLUMNS_TO_CLEAR()")
  
  for i = 1, 12 do
    pats_to_clear[i] = pattern_index
  end
  
  for i = 1, 12 do
    lins_to_clear[i] = line_index
  end
  
end

--STORE SONG LINES-----------------------------------------------------------------------------------
local function store_song_lines()
  print("STORE_SONG_LINES()")
--...we store the line values of all lines in track in song
      local y = 1
      for pos,line in song.pattern_iterator:lines_in_track(track_index,true) do
    
        lns_in_sng[y] = {}
    
        local z = 1
        while z < 13 do
      
          print("\nz = " .. z)
      
          lns_in_sng[y][z] = {
          song.patterns[pattern_index].tracks[track_index]:line(y):note_column(z).note_value,
          song.patterns[pattern_index].tracks[track_index]:line(y):note_column(z).instrument_value,
          song.patterns[pattern_index].tracks[track_index]:line(y):note_column(z).volume_value,
          song.patterns[pattern_index].tracks[track_index]:line(y):note_column(z).panning_value,
          song.patterns[pattern_index].tracks[track_index]:line(y):note_column(z).delay_value,
          song.patterns[pattern_index].tracks[track_index]:line(y):note_column(z).effect_number_value,
          song.patterns[pattern_index].tracks[track_index]:line(y):note_column(z).effect_amount_value
          }
          z = z + 1

        
        end--end 12 columns loop
      
        y = y + 1
      
      end--end lines in song loop
    
      print("recorded lines in track in song")
      lns_in_sng_amount = y - 1
end

--GET CURRENT LINE-----------------------------------------------------------------------------------
local function get_current_line() 
  print("GET_CURRENT_LINE()")
  app = renoise.app()
  song = renoise.song()

  track_type = song.selected_track.type--check the type of track that's selected
    
  if track_type ~= 1 then --if the track is master or send, show error...
    app:show_error("Please move edit cursor to a non-Master/Send track! Master/Send tracks are not supported with the Flourish tool.")
    
  else --...otherwise, we store some indexing info in memory... 
   
    sequence_size = #song.sequencer.pattern_sequence
    sequence_index = song.selected_sequence_index
    pattern_amount = #song.patterns
    pattern_index = song.selected_pattern_index
    track_index = song.selected_track_index
    line_amount = #song.patterns[pattern_index].tracks[track_index].lines
    line_index = song.selected_line_index  
    cur_lin_ref = song.patterns[pattern_index].tracks[track_index]:line(line_index)
    
    clear_columns_to_clear()--...clear our destructive columns clearing index
    
    notes_detected = 0 --...reset the amount of detected notes to 0...
      
    --...if the user has Non-Destructive editing activated, then store all lines in song...
    if non_destructive then store_song_lines() end
    
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
    
    print("cur_lin_ref: ") print(cur_lin_ref)
  
    --...we detect the amount of note columns in the track that have notes...
    for i = 1, 12 do  
      if not cur_lin_ref:note_column(i).is_empty then notes_detected = i end
    end    
    
    --...show the delay columns for the selected track...
    song.tracks[track_index].delay_column_visible = true 
    
    --...and confirm the new line selection to the user in the status bar
    show_status("Line " .. line_index .. " in Pattern " .. pattern_index .. " was selected for Flourish!")
    
    if flourish_window_created then --if we have already created a view window...
      --...reset our sliders to 0 upon setting a new line...
      vb.views.time_slider.value = 0
      vb.views.tension_slider.value = 0
    end
    
  end--close if statement
end

--UPDATE TEXT----------------------------------------------------------------------------------------
local function update_text()
  print("UPDATE_TEXT()")
  vb.views.my_text.text = "Selected Sequence: " .. sequence_index - 1 ..
        "\nSelected Pattern: " .. pattern_index - 1 ..
        "\nSelected Track: " .. track_index ..
        "\nSelected Line: " .. line_index - 1 ..
        "\n" .. notes_detected .. " Note Columns selected"
end

--FLOURISH-------------------------------------------------------------------------------------------
local function flourish()
  print("FLOURISH()")
  --if the user has Non-Destructive editing activated, then...
  if non_destructive then
  
    --...we restore all the lines for the selected track in the current pattern from cur_trk_lns_obj  
    local y = 1
    while y < lns_in_sng_amount do
  
      local z = 1
      while z < 13 do
    
        song.patterns[pattern_index].tracks[track_index]:line(y):note_column(z).note_value = lns_in_sng[y][z][1]
      
        song.patterns[pattern_index].tracks[track_index]:line(y):note_column(z).instrument_value = lns_in_sng[y][z][2]
      
        song.patterns[pattern_index].tracks[track_index]:line(y):note_column(z).volume_value = lns_in_sng[y][z][3]
      
        song.patterns[pattern_index].tracks[track_index]:line(y):note_column(z).panning_value = lns_in_sng[y][z][4]
      
        song.patterns[pattern_index].tracks[track_index]:line(y):note_column(z).delay_value = lns_in_sng[y][z][5]
      
        song.patterns[pattern_index].tracks[track_index]:line(y):note_column(z).effect_number_value = lns_in_sng[y][z][6]
      
        song.patterns[pattern_index].tracks[track_index]:line(y):note_column(z).effect_amount_value = lns_in_sng[y][z][7]
      
        z = z + 1
      
      end--end while z
    
      y = y + 1
    
    end--end while y
  
  print("ptn trk restored!")
  
  end--end "if non_destructive" statement
  
  --clear the line that we're flourishing
  song.patterns[pattern_index].tracks[track_index]:line(line_index):clear()
  
  for i = 1, notes_detected do  --for each of the notes detected on the current line...

    --...find the correct line offset to copy to based on our current Time slider value
    local line_index_offset = math.floor(((i - 1) * time) / 256)
    
    print("line_index: ",line_index)
    print("line_index_offset: ",line_index_offset)
    
    --...find correct sequence index, and line index in that sequence, to copy this note to...
    local new_seq_index,new_lin_index = find_new_line(sequence_index,line_index,line_index_offset)
    
    print("new_lin_index: ", new_lin_index)
    
    --convert sequence index to pattern index
    local new_pat_index = song.sequencer:pattern(new_seq_index)
    
    --find correct note column reference to copy to
    local column_to_copy_to = song.patterns[new_pat_index].tracks[track_index]:line(new_lin_index):note_column(i)
    
    if not non_destructive then --if we are not preserving what we end up flourishing over...

      --...clear the columns where we previously moved our notes to
      song.patterns[pats_to_clear[i]].tracks[track_index]:line(lins_to_clear[i]):note_column(i):clear()
      
      --...store/update our new columns to clear next time around
      pats_to_clear[i] = new_pat_index
      lins_to_clear[i] = new_lin_index
      
    end--end "if not non_destructive"
    
    --copy the values into the new line/note column      
    column_to_copy_to.note_value = cur_lin_clmn_vals[i][1]
    column_to_copy_to.instrument_value = cur_lin_clmn_vals[i][2]
    column_to_copy_to.volume_value = cur_lin_clmn_vals[i][3]
    column_to_copy_to.panning_value = cur_lin_clmn_vals[i][4]
    --column_to_copy_to.delay_value = cur_lin_clmn_vals[i][5] --we dont need the delay value
    column_to_copy_to.effect_number_value = cur_lin_clmn_vals[i][6]
    column_to_copy_to.effect_amount_value = cur_lin_clmn_vals[i][7]
  
    --new delay value to apply to the new line/note column
    column_to_copy_to.delay_value = math.floor(((i - 1) * time) % 256)    
    
  end--for loop close
end

--CREATE FLOURISH WINDOW-----------------------------------------------------------------------------
function create_flourish_window()
  print("CREATE_FLOURISH_WINDOW()")
  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT  

  window_title = "~ FLOURISH ~"  
  window_content = vb:column {    
    margin = DEFAULT_MARGIN,
    
    vb:text {   -- now add the first text into the inner column
      id = "my_text",
      style = "normal",
      font = "bold",
      text = "Selected Sequence: " .. sequence_index - 1 ..
        "\nSelected Pattern: " .. pattern_index - 1 ..
        "\nSelected Track: " .. track_index ..
        "\nSelected Line: " .. line_index - 1 ..
        "\n" .. notes_detected .. " Note Columns selected"
    },
  
    vb:horizontal_aligner {
      margin = DEFAULT_MARGIN,
      mode = "distribute",
      
      vb:text {
        text = "Time"
      },
        
      vb:text {
        text = "Tension"        
      }
    },
    
    vb:horizontal_aligner {
      margin = DEFAULT_MARGIN,
      mode = "distribute",
      
      vb:minislider {
        id = "time_slider",
        tooltip = "the time over which to spread the notes",
        min = -2277,
        max = 2277,
        value = 0,
        width = 17,
        height = 150,
        notifier = function(value)     
          time = -value
          show_status(("Time: %.2f"):format(time))
          if auto_apply then flourish() end
        end
      },
      
      vb:minislider {
        id = "tension_slider",
        tooltip = "(not yet implemented)",
        min = -1,
        max = 1,
        value = 0,
        width = 17,
        height = 150,
        notifier = function(value)                
          tension = value
          show_status(("Tension: %.2f"):format(tension))
          if auto_apply then flourish() end
        end
      }
              
    },--row close
    
    vb:row {
      margin = DEFAULT_MARGIN,
      vb:text {
        text = "Auto-Apply"
      },      
      vb:checkbox {
        tooltip = "Moving the sliders will update/apply the change in realtime",
        value = auto_apply,
        notifier = function(value)
          auto_apply = value
        end
      }
    },--auto-apply checkbox row close
    
     vb:row {
      margin = DEFAULT_MARGIN,
      vb:text {
        text = "Non-Destructive [Laggy!]"
      },      
      vb:checkbox {
        tooltip = "Flourish will keep track of content and will not overwrite any pattern data until a new line is set to be edited (this stores the entire song in memory, so it is very slow, only to be used in delicate circumstances)",
        value = non_destructive,
        notifier = function(value)
          clear_columns_to_clear()--...clear our destructive columns clearing index
          --...reset our sliders to 0
          vb.views.time_slider.value = 0
          time = 0
          vb.views.tension_slider.value = 0
          tension = 0
          flourish()
          non_destructive = value
          if value then store_song_lines() end
        end
      }
    },--auto-apply checkbox row close
    
    vb:row {
      margin = DEFAULT_MARGIN,
    
      vb:button {
        text = "Set Line",
        width = 60,
        notifier = function()        
          get_current_line()
          update_text()
        end
      },    
    
      vb:button {
        text = "FLOURISH!",
        width = 60,
        notifier = function()        
          flourish()
        end
      }
    }--row close
  
  }--column close
  
  flourish_window_created = true
      
end--end function

--SHOW FLOURISH WINDOW-------------------------------------------------------------------------------
local function show_flourish_window()
  print("SHOW_FLOURISH_WINDOW()")
  flourish_window_obj = app:show_custom_dialog(window_title, window_content)
end

--MAIN FUNCTION--------------------------------------------------------------------------------------
local function main_function()
  print("MAIN_FUNCTION()")
  get_current_line()
  if track_type == 1 then
    if not flourish_window_created then create_flourish_window() end
    update_text()
    if not flourish_window_obj or not flourish_window_obj.visible then show_flourish_window() end
  end
end

--SHOW WINDOW WITHOUT SETTING A NEW NOTE-------------------------------------------------------------
local function show_window_only()
  if not flourish_window_created then create_flourish_window() end
  if not flourish_window_obj or not flourish_window_obj.visible then show_flourish_window() end
end

--MENU/HOTKEY ENTRIES--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:M.O.Marmalade:Flourish...",
  invoke = function() main_function() end
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:M.O.Marmalade:Flourish - Show Window...",
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
  name = "Global:Tools:Flourish - Show Window...",
  invoke = function() show_flourish_window() end 
}
