breed [engines engine]
turtles-own [Vx Vy mass]
engines-own [force]
globals [
  dt
  dynaturtle
  schedule
  message
  ruler
  ruler-label
  ; the following are needed for the block-based schedule-engine procedure
  DURATION
  LAST-TICK-SCHEDULED
  TICKS-ON
  NEW-TIMES
  NEW-FORCES
]



to setup
  ca
  set schedule []
  foreach (list 0 90 180 270) [h ->
    create-engines 1 [
      set color orange
      set heading h
      hide-turtle
      set shape "fire"
    ]
  ]

  crt 1 [
    set color blue
    set dynaturtle self
    set shape "square"
    set mass 10
    create-links-with engines [
      set color orange
      set thickness .4
      hide-link
    ]
  ]

  crt 1 [
    set message self
    set size 0
  ]

  crt 1 [
    set ruler self
    create-link-with dynaturtle [hide-link]
    hide-turtle
    set shape "line"
    set color grey
    set size 2
    set heading 0
  ]

  crt 1 [
    set ruler-label self
    set size 0
  ]

  set dt 1 ;; This is the time step which gets related to ticks (e.g. if it seconds, then 1 sec = 1 tick, if you sent it to 0.5, the 0.5 seconds=1 tick)

  (ifelse
    maze = "none diagonal" [setup-no-maze]
    maze = "none horizontal" [setup-no-maze-horizontal]
    maze = "maze 1" [setup-maze-1]
    maze = "maze 2" [setup-maze-2]
    maze = "random target 1D" [setup-random-target "1D"]
    maze = "random target 2D" [setup-random-target "2D"]
  )

  reset-ticks

end

to setup-random-target [D]
  ask dynaturtle [
    let x ifelse-value random-float 1 < 0.5 [min-pxcor + 1] [max-pxcor - 1]
    setxy x round random-ycor
  ]

  crt 1 [
    (ifelse
      D = "1D" [pick-random-spot-1d]
      D = "2D" [pick-random-spot-2d]
    )
    ask patches in-radius 1.5 [set pcolor green]
    die
  ]

end

to pick-random-spot-1d
  setxy round random-xcor [ycor] of dynaturtle
  if distance dynaturtle < 5 [
    pick-random-spot-1d
  ]
end

to pick-random-spot-2d
  setxy round random-xcor round random-ycor
  if distance dynaturtle < 5 [
    pick-random-spot-2d
  ]
end

to setup-no-maze-horizontal
  let y min-pycor + 7.5
  ask dynaturtle [
    setxy min-pxcor + 7 y
  ]

  crt 1 [
    setxy (min-pxcor + 8 + world-width / 2) y
    ask patches in-radius 1.5 [set pcolor green]
    die
  ]
end


to setup-no-maze
  ask dynaturtle [
    setxy min-pxcor + 7 min-pycor + 7
  ]

  crt 1 [
    setxy (min-pxcor + 7 + world-width / 2) (min-pycor + 7 + world-height / 2)
    ask patches in-radius 1.5 [set pcolor green]
    die
  ]

end


to setup-maze-1

  crt 1 [
    setxy min-pxcor + 7 min-pycor + 7
    set heading 90
    repeat 2 [
      repeat world-width / 2 [
        ask patches in-radius 1.5 [
          set pcolor red
        ]
        fd 1
      ]
      lt 90
    ]
    ask patches in-radius 1.5 [set pcolor green]
    die
  ]
  ask patches with [pcolor = black and any? neighbors4 with [pcolor = red]] [
    set pcolor grey
  ]
  ask patches with [pcolor = red] [set pcolor black]

  ask dynaturtle [
    setxy min-pxcor + 7 min-pycor + 7
  ]
end

to setup-maze-2
  let x-start min-pxcor + 6
  let y-start min-pxcor + 3
  crt 1 [
    setxy x-start y-start

    set heading 0
    repeat world-height / 3 [
      ask patches in-radius 2 [
        set pcolor red
      ]
      fd 1
    ]

    set heading 45
    repeat world-height / 3 [
      ask patches in-radius 2.5 [
        set pcolor red
      ]
      fd 1
    ]

    set heading 90
    repeat world-height / 3 [
      ask patches in-radius 2 [
        set pcolor red
      ]
      fd 1
    ]

    ask patches in-radius 1.75 [set pcolor green]
    die
  ]

  ask patches with [pcolor = black and any? neighbors4 with [pcolor = red]] [
    set pcolor grey
  ]
  ask patches with [pcolor = red] [set pcolor black]
  ;ask patches with [pcolor = grey and pycor < y-start] [set pcolor black]

  ask dynaturtle [
    setxy x-start y-start
  ]
end





to go
  if ticks = 0 [
    schedule-engines
    log-data
  ]
  update-schedule

  run-engines

  if flew-away? [
    show-final-message "You flew away!"
    stop
  ]

  if crashed? [
    print "crashed"
    stop
  ]

  ask dynaturtle [
    set-pen-position
    setxy (xcor + Vx * dt) (ycor + Vy * dt)
  ]

  ask engines [
    visualize
  ]



  if reached-goal? [
    stop
    print "reached goal"
  ]

  tick
end

to show-ruler

  ask ruler [
    ifelse mouse-inside? [

      setxy mouse-xcor mouse-ycor
      show-turtle
      face dynaturtle
      rt 90
      ask my-links [show-link]
      ask ruler-label [
        move-to myself
        face dynaturtle
        fd distance dynaturtle / 2
        set label (word [precision distance dynaturtle 1] of myself " ")
      ]

    ] [
      hide-turtle
      ask my-links [hide-link]
      ask ruler-label [set label ""]
    ]
  ]


  display
end



to show-final-message [the-message]
  ask message [
    move-to dynaturtle

    ;;;set ycor ycor - 2
    ;set xcor xcor + 2
    if xcor < (min-pxcor + 5) [set xcor xcor + 5]
    if pycor = max-pycor [set ycor ycor - 1]
    ;if ycor < (min-pycor + 5) [set ycor ycor + 1]

    set label the-message
  ]
end

to-report flew-away?
  let will-fly-away? false

  ask dynaturtle [
    let new-x [xcor + Vx * dt] of dynaturtle
    let new-y [ycor + Vy * dt] of dynaturtle
    set will-fly-away? (
      new-x >= max-pxcor
      or new-x <= min-pycor
      or new-y >= max-pycor
      or new-y <= min-pycor
    )
    if will-fly-away?   [hide-turtle]
    ask engines [
      hide-turtle
      ask my-links [hide-link]
    ]
  ]
  report will-fly-away?

end

to-report crashed?
  let will-crash? false
  ask dynaturtle [
    if dyna-direction != "not moving" [
      set heading dyna-direction
      set will-crash? member? true map [d -> [pcolor = grey] of patch-ahead d] (range 0.5 (speed + .5) .1)

      if will-crash? [
        while [[pcolor != grey] of patch-here] [
          fd .1
        ]
        set shape "fire"
        set color red
        set heading 0
        set size 2

        ask engines [
          visualize
        ]
        show-final-message "you crashed!"
      ]
    ]
  ]
  report will-crash?
end

to-report reached-goal?
  let reached? false
  if [speed = 0 and [pcolor] of patch-here = green] of dynaturtle and empty? schedule [
    set reached? true
    show-final-message "you made it!"

  ]
  report reached?
end


to run-engines

  ask engines [set force 0]

  ; first condition checks there is anything left in schedule. Second condition checks that it isn't a wait block
  if (not empty? schedule) and (not empty? last first schedule) [
    let engine-forces last first schedule
    ask engine 0 [set force item 0 engine-forces]
    ask engine 1 [set force item 1 engine-forces]
    ask engine 2 [set force item 2 engine-forces]
    ask engine 3 [set force item 3 engine-forces]


    ask engine 0  [
      if force > 0 [
        accelerate-y (- force)
      ]
    ]

    ask engine 1  [
      if force > 0 [
        accelerate-x (- force)
      ]
    ]

    ask engine 2  [
      if force > 0 [
        accelerate-y force
      ]
    ]

    ask engine 3  [
      if force > 0 [
        accelerate-x force
      ]
    ]

  ]
end

to visualize
  ifelse force > 0 [
    visualize-on
  ] [
    visualize-off
  ]

end



to visualize-off
  hide-turtle
  ask my-links [hide-link]
end

to visualize-on
  move-to dynaturtle
  fd .5 + force / 5
  ask my-links [show-link]
  show-turtle
end


to accelerate-x [fx]
  ask dynaturtle [
    set Vx precision (Vx + (fx / mass) * dt) 5
  ]
end

to accelerate-y [fy]
  ask dynaturtle [
    set Vy precision (Vy + (fy / mass) * dt) 5
  ]
end



to set-pen-position
  ifelse draw-path? [
    pen-down
    set size .2
    stamp
    set size 1
  ] [
    pen-up
  ]
end

to-report dyna-direction
  let v-x [vx] of dynaturtle
  let v-y [vy] of dynaturtle
  ifelse precision (abs v-x + abs v-y) 5 = 0 [
    report "not moving"
  ] [
    report atan v-x v-y
  ]
end

to update-schedule
  if not empty? schedule and first-schedule-time-is-past? [
    set schedule butfirst schedule
  ]
end

to-report first-schedule-time-is-past?
  report last (first (first schedule)) <= ticks
end

to-report speed  ; dynaturtle procedure
  report sqrt (vx ^  2 + vy ^ 2)
end

to log-data
  ;; This is an empty procedure to be changed in Javascript for logging purposes
end

;to schedule-engines
;  set schedule lput [[0 10] [0 0 0 1]] schedule
;end
@#$#@#$#@
GRAPHICS-WINDOW
221
10
679
469
-1
-1
13.64
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
seconds
30.0

BUTTON
0
100
95
133
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
100
100
209
133
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
0
150
94
183
NIL
clear-drawing
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
100
150
211
183
draw-path?
draw-path?
0
1
-1000

MONITOR
0
188
95
233
speed
[speed] of dynaturtle
3
1
11

MONITOR
100
189
210
234
direction (angle)
dyna-direction
2
1
11

MONITOR
35
240
94
285
vx
[vx] of dynaturtle
3
1
11

MONITOR
100
240
155
285
vy
[vy] of dynaturtle
3
1
11

CHOOSER
0
50
130
95
maze
maze
"none horizontal" "none diagonal" "maze 1" "maze 2" "random target 1D" "random target 2D"
4

BUTTON
150
50
210
95
ruler
show-ruler
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
0
287
200
467
Velocity
seconds (s)
meters / s
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Vx" 1.0 0 -16777216 true "" "plot [vx] of dynaturtle"
"Vy" 1.0 0 -13345367 true "" "Plot [vy] of dynaturtle"

TEXTBOX
0
133
209
161
--------------------------------
11
0.0
1

TEXTBOX
5
20
155
38
Spaceship's mass = 10kg
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fire
true
0
Polygon -7500403 true true 151 286 134 282 103 282 59 248 40 210 32 157 37 108 68 146 71 109 83 72 111 27 127 55 148 11 167 41 180 112 195 57 217 91 226 126 227 203 256 156 256 201 238 263 213 278 183 281
Polygon -955883 true false 126 284 91 251 85 212 91 168 103 132 118 153 125 181 135 141 151 96 185 161 195 203 193 253 164 286
Polygon -2674135 true false 155 284 172 268 172 243 162 224 148 201 130 233 131 260 135 282

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

ufo top
false
0
Circle -1 true false 15 15 270
Circle -16777216 false false 15 15 270
Circle -7500403 true true 75 75 150
Circle -16777216 false false 75 75 150
Circle -7500403 true true 60 60 30
Circle -7500403 true true 135 30 30
Circle -7500403 true true 210 60 30
Circle -7500403 true true 240 135 30
Circle -7500403 true true 210 210 30
Circle -7500403 true true 135 240 30
Circle -7500403 true true 60 210 30
Circle -7500403 true true 30 135 30
Circle -16777216 false false 30 135 30
Circle -16777216 false false 60 210 30
Circle -16777216 false false 135 240 30
Circle -16777216 false false 210 210 30
Circle -16777216 false false 240 135 30
Circle -16777216 false false 210 60 30
Circle -16777216 false false 135 30 30
Circle -16777216 false false 60 60 30

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
