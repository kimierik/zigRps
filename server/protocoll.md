# communication protocoll between client and server



 ## client to server

first byte
protocoll version 


second byte

|msg type| | | | | | |
|--      |-|-|-|-|-|-|
|00|0|0|0|0|0|0|


msg types

pong
00

play move
01

|msg type| | | |rock|paper|cissors|
|--|-|-|-|-|-|-|
|00|0|0|0|0|0|0|

ask status (ping server)
10

client disconnect
11

the three last bits are only used if the messege type is play move


 ## server to client



first byte
protocoll version 


second byte

|msg type | | |rock|paper|cissors|
|---|-|-|-|-|-|
|000|0|0|0|0|0|


000 ping

001 opponent plays move


010 server status update
opponent connected                  1
opponent disconnect                 2
please wait                         3
received incorrect messege from you 4
(0b01000000 | status type)


011 game over

100 opponent move reveal


