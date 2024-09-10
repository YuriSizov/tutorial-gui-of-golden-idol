## Tutorial: The GUI of the Golden Idol

This is a tutorial project that demonstrates how core mechanics of
the game _[The Case of the Golden Idol](https://www.thegoldenidol.com/)_
can be implemented in Godot 4. This project is not affiliated with
_Color Gray_ or _The Golden Idol_ franchise.

This project is not based on the actual implementation in the game,
but is an experiment in how this can be achieved based on the information
available to players of the game.

This project is compatible with **Godot 4.3**.


## Considerations

Every problem can have a number of solutions, with the one eventually
chosen being picked for how well it addresses the goals and the
limitations given.

For this project I've decided to assume that:

- We want a native solution, possible with built-in nodes and GDScript alone.
- We want to make it as straightforward as possible for level designers to
create scenarios.
- Only a subset of the game's features needs to be replicated: picking clues
from source texts, placing clues in blanks in the final document, validating
the results.

The solution provided here fits these rules, but isn't some ideal perfect
solution. It can be changed, refactored, extended based on your needs, on
feedback from your team, on design goals of your project.

The purpose of this project is only to demonstrate and teach how this
problem can be approached.


## License

This project is provided under an [MIT license](LICENSE).
