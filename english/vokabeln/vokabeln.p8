pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- einfacher englisch-vokabeltrainer in pico-8
-- farben und zahlen bis 10 und weitere vokabeln

-- farben und vokabeln als fragen und antworten
local vocab = {
 {question = "1", answer = "one"},
 {question = "2", answer = "two"},
 {question = "3", answer = "three"},
 {question = "4", answer = "four"},
 {question = "5", answer = "five"},
 {question = "6", answer = "six"},
 {question = "7", answer = "seven"},
 {question = "8", answer = "eight"},
 {question = "9", answer = "nine"},
 {question = "10", answer = "ten"},
 {question = "rot", answer = "red"},
 {question = "gruen", answer = "green"},
 {question = "blau", answer = "blue"},
 {question = "gelb", answer = "yellow"},
 {question = "schwarz", answer = "black"},
 {question = "weiss", answer = "white"},
 {question = "schere", answer = "scissors"},
 {question = "radiergummi", answer = "rubber"},
 {question = "lineal", answer = "ruler"},
 {question = "buch", answer = "book"},
 {question = "stift", answer = "pen"},
 {question = "bleistift", answer = "pencil"},
 {question = "tisch", answer = "desk"},
 {question = "stuhl", answer = "chair"},
 {question = "federmappe", answer = "pencil case"},
 {question = "schulranzen", answer = "school bag"},
 {question = "klebestift", answer = "glue stick"},
 {question = "schule", answer = "school"},
 {question = "affe", answer = "monkey"},
 {question = "fledermaus", answer = "bat"},
 {question = "elefant", answer = "elephant"},
 {question = "fuchs", answer = "fox"},
 {question = "loewe", answer = "lion"},
 {question = "vogel", answer = "bird"},
 {question = "nilpferd", answer = "hippo"},
 {question = "krokodil", answer = "crocodile"},
 {question = "frosch", answer = "frog"},
 {question = "schlange", answer = "snake"},
 {question = "ratte", answer = "rat"},
 {question = "schaf", answer = "sheep"},
 {question = "hund", answer = "dog"},
 {question = "koala", answer = "koala"},
 {question = "katze", answer = "cat"},
 {question = "tapir", answer = "tapir"},
 {question = "pferd", answer = "horse"},
 {question = "kamel", answer = "camel"},
 {question = "schwein", answer = "pig"},











 

 



}

local current_question = ""
local user_answer = ""
local hits = 0
local misses = 0
local current_index = 1
local game_over = false
local show_correct_answer = false
local correct_answer = ""
local wrong_answer = ""
local alphabet = "abcdefghijklmnopqrstuvwxyz " -- leerzeichen nach "z" hinzugefれもgt
local cursor_x = 0
local cursor_y = 0

function new_question()
 current_index = flr(rnd(#vocab)) + 1
 current_question = vocab[current_index].question
 correct_answer = vocab[current_index].answer
end

new_question()

function _update()
 if game_over then
  if btnp(4) or btnp(5) then
   game_over = false
   user_answer = ""
   wrong_answer = ""
   show_correct_answer = false
   new_question()
  end
  return
 end

 -- cursor bewegen
 if btnp(0) then -- links-taste
  cursor_x -= 1
  if cursor_x < 0 then
   cursor_x = 9
  end
 elseif btnp(1) then -- rechts-taste
  cursor_x += 1
  if cursor_x > 9 then
   cursor_x = 0
  end
 elseif btnp(2) then -- hoch-taste
  cursor_y -= 1
  if cursor_y < 0 then
   cursor_y = 2
  end
 elseif btnp(3) then -- runter-taste
  cursor_y += 1
  if cursor_y > 2 then
   cursor_y = 0
  end
 end

 -- taste x (taste 5) drれもcken, um den aktuellen buchstaben, del oder enter auszufれもhren
 if btnp(4) or btnp(5) then
  if cursor_y == 2 and cursor_x == 7 then
   -- "del" taste: letztes zeichen der antwort lれへschen
   user_answer = sub(user_answer, 1, #user_answer - 1)
  elseif cursor_y == 2 and cursor_x == 8 then
   -- "enter" taste: antwort bestれさtigen
   if user_answer == correct_answer then
    hits += 1
    show_correct_answer = false
    user_answer = ""
    new_question()
   else
    -- falsche antwort, zeige die richtige antwort und die eingegebene falsche antwort an
    misses += 1
    show_correct_answer = true
    wrong_answer = user_answer
    game_over = true
   end
  else
   -- anderen buchstaben zur antwort hinzufれもgen
   local selected_letter = sub(alphabet, cursor_y * 10 + cursor_x + 1, cursor_y * 10 + cursor_x + 1)
   user_answer = user_answer .. selected_letter
  end
 end
end

function draw_keyboard()
 -- tastatur zeichnen (10 buchstaben pro zeile, 3 zeilen)
 local x_start = 10
 local y_start = 80
 for i=0,2 do
  for j=0,9 do
   if i == 2 and j == 7 then
    -- letzte zelle in der 3. reihe ist "del"
    print("<", x_start + j * 8, y_start + i * 8, 7)
   elseif i == 2 and j == 8 then
    -- zweitletzte zelle in der 3. reihe ist "enter"
    print("!", x_start + j * 8, y_start + i * 8, 7)
   else
    -- buchstaben anzeigen, leerzeichen an richtiger stelle nach "z"
    local letter = sub(alphabet, i * 10 + j + 1, i * 10 + j + 1)
    print(letter, x_start + j * 8, y_start + i * 8, 7)
   end
  end
 end

 -- cursor zeichnen
 rect(x_start + cursor_x * 8 - 2, y_start + cursor_y * 8 - 2, x_start + cursor_x * 8 + 6, y_start + cursor_y * 8 + 6, 10)
end

function _draw()
 cls()
  if show_correct_answer then
   print("frage: "..current_question, 10, 30, 7)
   print("deine antwort: "..wrong_answer, 10, 40, 8)
   print("richtige antwort: "..correct_answer, 10, 50, 12)
   print("versuche es noch mal!", 20, 70, 7)
 else
  print("frage: "..current_question, 10, 30, 7)
  print("antwort: "..user_answer, 10, 40, 7)
  
  -- tastatur am unteren bildschirmrand anzeigen
  draw_keyboard()

  print("hits: "..hits, 10, 5, 3)
  print("misses: "..misses, 60, 5, 8)
 end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
