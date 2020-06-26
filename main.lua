--MyFirstTest--

--GLOBALS--------------------------------------------------------------------------------------------

app = renoise.app()
pattern_amount = nil
pattern_index = nil
track_index = nil
track_type = nil
line_index = nil

cur_lin_obj = nil
lns_in_sng = {}
lns_in_sng_amount = nil
notes_detected = 0

time = 0
tension = 0
auto_apply = false
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

--GET CURRENT LINE-----------------------------------------------------------------------------------
local function get_current_line()  

  track_type = renoise.song().selected_track.type--check the type of track that's selected
    
  if track_type ~= 1 then --if the track is master or send, show error...
    app:show_error("Please move edit cursor to a non-Master/Send track! Master/Send tracks are not supported with the Flourish tool.")
    
  else --...otherwise, we store some indexing info in memory...  

    pattern_amount = #renoise.song().patterns
    pattern_index = renoise.song().selected_pattern_index
    track_index = renoise.song().selected_track_index
    line_index = renoise.song().selected_line_index  
    
    notes_detected = 0 --...reset the amount of detected notes to 0...
    
    local y = 1
    for pos,line in renoise.song().pattern_iterator:lines_in_track(track_index,true) do
      lns_in_sng[y] = line
      y = y + 1
    end
    print("recorded lines in track in song")
    lns_in_sng_amount = y - 1
    
    print("lns_in_sng_amount = " .. lns_in_sng_amount)
    for key, value in ipairs(lns_in_sng) do
      print("\nkey: " .. key)
      print("\nvalue: ") print(value)
    end
    
    --...we store the selected line in cur_lin_obj...
    cur_lin_obj = renoise.song().patterns[pattern_index].tracks[track_index]:line(line_index)
    print("cur_lin_obj: ") print(cur_lin_obj)
  
    --...we detect the amount of note columns in the track that have notes...
    for i = 1, 12 do  
      if not cur_lin_obj.note_columns[i].is_empty then notes_detected = i end
    end    
    
    --...show the delay columns for the selected track...
    renoise.song().tracks[track_index].delay_column_visible = true 
    
    --...and confirm the new line selection to the user in the status bar
    show_status("Line " .. line_index .. " in Pattern " .. pattern_index .. " was selected for Flourish!")
    
  end--close if statement
end

--UPDATE TEXT----------------------------------------------------------------------------------------
local function update_text()
  vb.views.my_text.text = "Selected Pattern: " .. pattern_index ..
  "\nSelected Track: " .. track_index ..
  "\nSelected Line: " .. line_index ..
  "\n" .. notes_detected .. " Note Columns selected"
end

--FLOURISH-------------------------------------------------------------------------------------------
local function flourish()
  
  --...we restore all the lines for the selected track in the current pattern from cur_trk_lns_obj
  
  local y = 1
  while y < lns_in_sng_amount do
      renoise.song().patterns[pattern_index].tracks[track_index].lines[y]:copy_from(lns_in_sng[y])
      y = y + 1
    end
  print("ptn trk restored!")
  
  for i = 1, notes_detected do

    --find correct line/note column to copy to
    local column_to_copy_to = renoise.song().patterns[pattern_index].tracks[track_index].lines[line_index + (math.floor(((i - 1) * time) / 256))].note_columns[i]
    
    --copy the values into the new line/note column
    column_to_copy_to:copy_from(cur_lin_obj.note_columns[i])
  
    --delay value to apply to the new line/note column
    column_to_copy_to.delay_value = math.floor(((i - 1) * time) % 256)    
    
  end--for loop close
end

--CREATE FLOURISH WINDOW-----------------------------------------------------------------------------
function create_flourish_window()

  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT  

  window_title = "~ FLOURISH ~"  
  window_content = vb:column {    
    margin = DEFAULT_MARGIN,
    
    vb:text {   -- now add the first text into the inner column
      id = "my_text",
      style = "normal",
      font = "bold",
      text = "Selected Pattern: " .. pattern_index ..
        "\nSelected Track: " .. track_index ..
        "\nSelected Line: " .. line_index ..
        "\n" .. notes_detected .. " Note Columns selected"
    },
  
    vb:horizontal_aligner {
      margin = DEFAULT_MARGIN,
      mode = "distribute",
      
      vb:column {
        margin = DEFAULT_MARGIN,
    
        vb:text {
          text = "Time"
        },
    
        vb:minislider {
          min = -10000,
          max = 10000,
          value = 0,
          width = 20,
          height = 150,
          notifier = function(value)     
            time = -value
            show_status(("Time: %.2f"):format(time))
            if auto_apply then flourish() end
          end
        }        
      },--Time slider column close  
      
      vb:column {
        margin = DEFAULT_MARGIN,
    
        vb:text {
        text = "Tension"        
        },
  
        vb:minislider {
          min = -1,
          max = 1,
          value = 0,
          width = 20,
          height = 150,
          notifier = function(value)                
            tension = value
            show_status(("Tension: %.2f"):format(tension))
            if auto_apply then flourish() end
          end
        }
        
      }--Tension slider column close 
              
    },--row close
    
    vb:row {
      margin = DEFAULT_MARGIN,
      vb:text {
        text = "Auto-Apply"
      },      
      vb:checkbox {
        value = false,
        notifier = function(value)
          auto_apply = value
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
  flourish_window_obj = app:show_custom_dialog(window_title, window_content)  
end

--MAIN FUNCTION--------------------------------------------------------------------------------------
local function main_function()
  get_current_line()
  if track_type == 1 then
    if not flourish_window_created then create_flourish_window() end
    update_text()
    if not flourish_window_obj or not flourish_window_obj.visible then show_flourish_window() end
  end
end

--MENU/HOTKEY ENTRIES--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:M.O.Marmalade:Flourish...",
  invoke = function() main_function() end
}

renoise.tool():add_keybinding {
  name = "Global:Tools:Flourish...",
  invoke = function() main_function() end 
}
