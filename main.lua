--MyFirstTest--

local function show_status(message)
  renoise.app():show_status(message)
  print(message)
end

local function flourish(song, pattern_amount, pattern_index, track_index, track_type, line_index)

  if track_type == 1
  then  
    song.tracks[track_index].delay_column_visible = true
  end

end

function hello_boi()

  local song = renoise.song()
  local pattern_amount = table.getn(song.patterns)
  local pattern_index = song.selected_pattern_index
  local track_index = song.selected_track_index
  local track_type = song.selected_track.type
  local line_index = song.selected_line_index

  local time = 0 --rotary tester
  local tension = 0

  local vb = renoise.ViewBuilder()  

  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT  
  
  local prompt_title = "hello_boi"  
  local prompt_content = vb:column {    
    margin = DEFAULT_MARGIN,
      
    vb:text {   -- now add the first text into the inner column
      text = "Total # of Patterns: " .. pattern_amount .. 
        "\nCurrent Pattern: " .. pattern_index ..
        "\nCurrent Track: " .. track_index ..
        "\nTrack Type: " .. track_type ..
        "\nCurrent Line: " .. line_index
    },
    
    vb:row {
      margin = DEFAULT_MARGIN,
      
      vb:text {
        text = "Time"
      },
      
      vb:rotary {
        min = -1,
        max = 1,
        value = 0,
        width = 2*DEFAULT_CONTROL_HEIGHT,
        height = 2*DEFAULT_CONTROL_HEIGHT,
        notifier = function(value)
          show_status(("time = '%.2f'"):format(value))      
          time = value
          print("time = " .. time)
        end
      },     
      
    },--row close
    
    vb:row {
      margin = DEFAULT_MARGIN,
    
      vb:text {
        text = "Tension"
      },
    
      vb:rotary {
        min = -1,
        max = 1,
        value = 0,
        width = 2*DEFAULT_CONTROL_HEIGHT,
        height = 2*DEFAULT_CONTROL_HEIGHT,
        notifier = function(value)
          show_status(("tension = '%.2f'"):format(value))      
          tension = value
          print("tension = " .. tension)
        end
      }
    
    },--row close
    
    vb:button {
      text = "Hit me",
      width = 60,
      notifier = function()
        show_status("button was hit!")
        flourish(song, pattern_amount, pattern_index, track_index, track_type, line_index)
      end
    }
    
  }--column close

  renoise.app():show_custom_dialog(prompt_title, prompt_content)
    
end
-----------------------------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:MyFirstTest:Hello Boi...",
  invoke = function() hello_boi() end
}

renoise.tool():add_keybinding {
  name = "Global:Tools:Hello Boi...",
  invoke = function() hello_boi() end 
}
