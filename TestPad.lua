-- add your test snippets and other code here, that you want to quickly
-- try out without writing a full blown 'tool'...

local song = renoise.song()
local pattern_amount = #song.patterns
local pattern_index = song.selected_pattern_index
local track_index = song.selected_track_index
local track_type = song.selected_track.type
local track_amount = #song.tracks
local line_index = song.selected_line_index

cur_lin_obj = song.patterns[pattern_index].tracks[track_index]:line(line_index)
--renoise.PatternLine object

print("\ntrack amount: " .. track_amount)
print("\npattern amount: " .. pattern_amount)
print("\nline_index: " .. line_index)
print("\nthis line in this track: ")
print(cur_lin_obj)

columns = {}

for i = 1, 12 do
columns[i] = cur_lin_obj.note_columns[i]
end

print(columns[1]) -- prints first column current line

--copies the current line's first column to the next line's first column
song.patterns[pattern_index].tracks[track_index].lines[line_index + 1].note_columns[1]:copy_from(columns[1])

song.patterns[pattern_index].tracks[track_index].lines[line_index + 1].note_columns[1].delay_value = 16 --sets the new line's delay to "10"

--clears the current line
song.patterns[pattern_index].tracks[track_index].lines[line_index].note_columns[1]:clear()






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
