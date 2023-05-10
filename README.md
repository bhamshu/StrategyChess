# Stages of the Play

**EnterName** 

1. When a new player comes without any player_id in localstorage, they're shown a home screen with an empty chess board and their gray pieces on the side. They're asked to enter a unique username. All the other board areas are deactivated. 
2. After entering, it sends a request to backend. If it's unique, they're sent a player_id. Else asked to reenter.

**Strategise** 

3. After successfully choosing, they are asked to drag all the pieces on main board. The upper half of the main board is shown but deactivated. On the upper left, they see a list of ready players. On the upper right they see a list of incoming requests. On the bottom middle they see a place to write their own name. All these are deactivated right now.

**PartnerSelection** 

4. After that, they see themselves added to the list of ready players. And all ready players except themselves have a button saying "Send request".
5. If someone sends them a request, they see that on the upper right with option to accept or decline.

**GamePlay** 

6. If someone accepts their request or if they accept, the game starts. Players are assigned "black" and "white" colors randomly.
7. All moves get validated before executing. After each move, they both get the new state of board.

**GameOver** 

8.  If the king is dead or a player resigns, they both see the name of winner.
9.  In this game there are no en passant, castling, pawn promotion, draw rules or any other advanced rules.

