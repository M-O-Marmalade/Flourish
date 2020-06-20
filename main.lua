--MyFirstTest--

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:MyFirstTest:Hello Boi...",
  invoke = function() hello_boi() end
}

renoise.tool():add_keybinding {
  name = "Global:Tools:Hello Boi...",
  invoke = function() hello_boi() end 
}

function text_changed()
renoise.app():show_status("text was changed")
end

function hello_boi()

  local vb = renoise.ViewBuilder()
  
  -- get some consts to let the dialog look like Renoises default views...
  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
    
  
  local prompt_title = "Hello Boi ._."
  local prompt_buttons = {"xNO!", "OK!"};  
  local prompt_content = vb:column {  -- start with a 'column' to stack other views vertically:
    
    margin = DEFAULT_MARGIN,  -- set a border of DEFAULT_MARGIN around our main content   
    
    vb:column { -- and create another column to align our text in a different background
      
      style = "group",  -- background that is usually used for "groups"      
      
      margin = DEFAULT_MARGIN,  -- add again some "borders" to make it more pretty      
      
      vb:text {   -- now add the first text into the inner column
         text = "big, strong text\n"..
         "Renoise API Version " .. renoise.API_VERSION .. 
         "\nRenoise Version " .. renoise.RENOISE_VERSION,
         font = "big",
         style = "strong",
         align = "center"
      },
         
      vb:text {   -- now add the second text into the inner column
         text = "bold, normal text\n"..
         "Renoise API Version " .. renoise.API_VERSION .. 
         "\nRenoise Version " .. renoise.RENOISE_VERSION,
         font = "bold",
         style = "normal",
         align = "center"
      },
      
      vb:text {   -- now add the second text into the inner column
         text = "let's see if centered text will expand the window size\nand if it will stay centered\n"..
         "Renoise API Version " .. renoise.API_VERSION .. 
         "\nRenoise Version " .. renoise.RENOISE_VERSION,
         font = "bold",
         style = "normal",
         align = "center"
      },
      
      vb:textfield {
        align = "center"
      }
            
    }
    
  }

  renoise.app():show_custom_prompt(prompt_title, prompt_content, prompt_buttons)

end

  -- lets go on and start to use some real controls (buttons & stuff) now...
