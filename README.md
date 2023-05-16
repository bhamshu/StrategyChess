See Frontend repository [here](https://github.com/bhamshu/FrontendStrategyChess/), play [here](http://ec2-3-95-161-63.compute-1.amazonaws.com:3001/)

# Navigating the Codebase

See the api endpoints at `config/routes.rb`), and the corresponding methods at
`app/controllers/api`. APIs are arranged roughly in the order the players will call them, which in turn depends upon the stages of the play explained below.

Find the models in `app/models/` (and to see the corresponding schemas, refer `db/schema.rb`). 

Finally, take a look at the tests in `spec/requests/api/`.

To **Run the Project**, go to the root directory and simply run
```
docker-compose up --build
```

To **Run Tests**, go to the root directory and simply run
```
docker-compose run -e "RAILS_ENV=test" web bundle exec rspec ./spec/requests/api/
```


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


# TODOs
* Highlight the initial and the final boxes when the other player moves.
* Text chat between players. If it's not too costly to support, live audio chat would be awesome to have.
* UI on mobile phones is terrible. Active players and active requests are going out of the screen. Fix that.
* Every once in a while (low single digit percentage), the board state doesn't refresh. Look into it. If the issue persists, update board state every few seconds.
* On hovering over a piece, the cursor that appears is the "text edit" cursor. It should be a grab one or a pointer one (See [here](https://www.w3schools.com/cssref/tryit.php?filename=trycss_cursor))
* Currently, the player is asked to enter a name again. What's worse, the old name can't be reused as it's considered as "taken by someone else". Fix this.

