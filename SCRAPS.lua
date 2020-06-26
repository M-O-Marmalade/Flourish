
y = x^2
y = x^8
y = x^0.2



--[[notes = {}
instruments = {}
volumes = {}
pan_vals = {}
delays = {}
effect_nums = {}
effect_vals = {}

for i = 1, 12 do
  notes[i] = cur_lin_obj.note_columns[i].note_string
  instruments[i] = cur_lin_obj.note_columns[i].instrument_string
  volumes[i] = cur_lin_obj.note_columns[i].volume_string
  pan_vals[i] = cur_lin_obj.note_columns[i].panning_string
  delays[i] = cur_lin_obj.note_columns[i].delay_string
  effect_nums[i] = cur_lin_obj.note_columns[i].effect_number_string
  effect_vals[i] = cur_lin_obj.note_columns[i].effect_amount_string
end--]]

--[[for pos,line in renoise.song().pattern_iterator:note_columns_in_pattern_track(pattern_index,track_index,true) do
  print("\npos: ")
  print(pos)
  print("  line: ")
  print(line)
end--]]


--[[

  --copies the current line's first column to the next line's first column
  song.patterns[pattern_index].tracks[track_index].lines[line_index + 1].note_columns[1]:copy_from(columns[1])

  song.patterns[pattern_index].tracks[track_index].lines[line_index + 1].note_columns[1].delay_value = 16 --sets the new line's delay to "10"

  --clears the current line
  song.patterns[pattern_index].tracks[track_index].lines[line_index].note_columns[1]:clear()
  
--]]
