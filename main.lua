--MyFirstTest--

--GLOBALS--------------------------------------------------------------------------------------------

app = renoise.app()
song = nil
pattern_amount = nil
pattern_index = nil
track_index = nil
track_type = nil
line_index = nil

cur_lin_obj = nil
notes_detected = 0

time = 0
tension = 0
auto_apply = false

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

  song = renoise.song()
  pattern_amount = #song.patterns
  pattern_index = song.selected_pattern_index
  track_index = song.selected_track_index
  track_type = song.selected_track.type
  line_index = song.selected_line_index
  
  cur_lin_obj = song.patterns[pattern_index].tracks[track_index]:line(line_index)
  notes_detected = 0
    
  if track_type ~= 1 then --if the track is master or send, show error
    app:show_error("Please move edit cursor to a non-Master/Send track! Master/Send tracks are not supported with the Flourish tool.")
    
  else  --otherwise, store the selected line in cur_lin_obj
    for i = 1, 12 do    
      if not cur_lin_obj.note_columns[i].is_empty then notes_detected = i end
    end
    
    --show the delay columns for the selected track in case they are hidden
    song.tracks[track_index].delay_column_visible = true 
    
    --confirm the new line selection
    show_status("Line " .. line_index .. " in Pattern " .. pattern_index .. " was selected for Flourish!")
    
  end  
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
  
  for i = 1, notes_detected do
    song.patterns[pattern_index].tracks[track_index].lines[math.floor(line_index + (i - 1) * time)].note_columns[i]:copy_from(cur_lin_obj.note_columns[i])
  end

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
          min = -1,
          max = 1,
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
