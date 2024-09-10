## The GUI of the Golden Idol

### Chapter I: Introduction

_[The Case of the Golden Idol](https://www.thegoldenidol.com/)_ is a detective game in which you pick word clues from various texts spread across multiple crime scenes in various scenarios. You then use those clues to build a dossier of sorts, by filling in the blanks, that summarizes your read on the situation and the conclusion, resolving each case.

It's a really wonderful game, so be sure to check it out, if you haven't! And it's made with Godot, which inspired me to try and figure out how its core mechanic of picking and placing words can be implemented in the engine.

> [!NOTE]
> If you're simply interested in the final solution, just check out this repository and look at its fairly comprehensively documented code. Feel free to use it for your projects too, if you want — it's licensed under MIT!
> 
> But, if you feel like reading a bit more, then please press on!

In the following paragraphs I will talk about not only the specific solution to the presented problem, but also how it has come to be, how such decisions are made in practice.


### Chapter II: Considerations

To approach any problem you must first understand the conditions, the limitations that apply. Every problem can have a number of potential solutions, but only one is eventually chosen, based on how well it satisfies these given conditions.

In practice, you won't always be able to have a comprehensive list of things to consider when you start on some task. You often will arrive to it in the process, through experiment and iteration. For this tutorial I will conveniently define every limitation from the get go:

1. We want a native solution, possible with built-in nodes, engine features, and GDScript alone.
2. We want to make it as straightforward as possible for level designers to create content for the scenarios.
3. Only a subset of the game's features needs to be replicated:
   - Picking clues from source texts;
   - Placing clues in blanks in the final document;
   - Validating the results.

The following solution fits these rules, but it isn't some ideal perfect solution. It can be modified, refactored, and extended based on your own needs, on the feedback from your team, on design goals of your project.


### Chapter III: Collecting clues (naively)

In the game you go through a number of semi-static scenes and interact with elements in them, which eventually bring up some kind of document, a piece of paper, a ticket, a chalkboard — anything with text written on it. Some words in the text would be highlighted as potential clues, and you are expected to press on these words to add them to your word bank.

Let's trivialize this to a simple mechanic: display some text with highlighted words which can be clicked.

Luckily, Godot has just the node for that — `RichTextLabel`. The term "rich text" is used to describe printed or inputted text that supports advanced formatting, as opposed to "plain text". The `RichTextLabel` node is a rich text counterpart of `Label`, which can be used to display plain text.

To format text in the `RichTextLabel` node you use a syntax called _BBcode_, an old system from when internet forums (a.k.a **B**ulletin **B**oards) were all the rage. The formatting tags in this system typically look like this: `[tag]content[/tag]`. [Godot comes with a handful](https://docs.godotengine.org/en/stable/tutorials/ui/bbcode_in_richtextlabel.html) of pretty standard BBcode tags, such as `[b]`, `[i]`, `[u]`, available out of the box.

The one that is interesting to us in this case is `[url]`, which is used to make certain parts of your text clickable and interactive. The name "url" was chosen by convention, but this tag is not limited to turning text into links. Instead, you are given full control over what happens when the user clicks on the text inside of the `[url]` tag.

To set this up, create a new scene with a `RichTextLabel` node in it. By default, this node acts pretty much like `Label` when displaying text, so make sure to enable its `BBCode Enabled` property in the inspector dock. For its text use the following:

```
The cases — there are a [url]dozen[/url] — immediately grow more elaborate and intricate, involving more suspects, murkier [url]motives[/url], tons of unrelated clues, and plenty of secrets.
```

If you run your scene now, you should see words "dozen" and "motives" decorated with an underline. When you hover over them, the pointing hand cursor appears. But clicks don't appear to be doing anything. That is because you need to script the `RichTextLabel` node and decide how to handle each click. Add a new script to the node, and create a method connected to its `meta_clicked` signal.

```gdscript
extends RichTextLabel


func _ready() -> void:
	meta_clicked.connect(_handle_meta_clicked)


func _handle_meta_clicked(value: Variant) -> void:
	pass
```

To fulfill our goal right now we can complete the `_handle_meta_clicked()` method by emitting some sort of signal with the text content of the `[url]` tag.

```gdscript
extends RichTextLabel

signal clue_clicked(value: String)


func _handle_meta_clicked(value: Variant) -> void:
	# Variant type will be automatically cast to String, if it is a compatible type.
	clue_clicked.emit(value)
```

However, there are two problems with this approach.

The first one may be rather obvious: we don't have a lot of control over how clues look in your text. There are standard formatting tags at our disposal, but for a highly stylized game like _The Case of the Golden Idol_ you may want to do more than that, use some extra flair, draw a panel around it — stuff like that. Frankly, you can't even control the underline thickness of `[url]` tags, as it is derived from the font you use.

The second problem is more of a practical issue. When designing puzzle games you want to make sure that levels are valid and can be solved, that accidental changes or even stuff like applying internationalization to your game doesn't render it broken. Whether you do automatic testing or not, it's always useful to implement checks and debug features in a bigger production to save yourself a lot of time and prevent regressions.

How does that conflict with `[url]` tags? Simply put, you can't interact with them through code. Sure, there is always the brute force solution: parse your formatted text with some custom script that can extract BBcode formatting. But that's a lot of work, and it can be error prone, all the while the engine already does the parsing in some shape or form. That is why we decided early on that our solution must be as native as possible, to benefit from the engine implementation in place of creating our own.


### Chapter IV: Collecting clues (but in an unexpected way)

So, how can we interact with tags in the `RichTextLabel` node in a way that benefits from the engine doing most of the work? Well, Godot provides a way for us to extend `RichTextLabel` with custom tags by implementing a custom `RichTextEffect`.

Custom effect tags are great for giving your texts some extra flair, and all you need to do to create one is make a new script with the following content:

```gdscript
@tool
class_name HighlightTextEffect extends RichTextEffect

var bbcode: String = "highlight"

func _process_custom_fx(char_data: CharFXTransform) -> bool:
	char_data.color = Color.YELLOW
	
	return true
```

Then select your `RichTextLabel` node, find the "Markup" section in the inspector dock, and add your newly available `HighlightTextEffect` effect to the `Custom Effects` property. Make sure to mark it as local to scene, so the effect instance is uniquely associated with its `RichTextLabel`. Alternatively, you can add effects from code using the `install_effect()` method.

To test that this works, modify the text to use the new tag and run the scene again.

```
The cases — there are a [highlight]dozen[/highlight] — immediately grow more elaborate and intricate, involving more suspects, murkier [highlight]motives[/highlight], tons of unrelated clues, and plenty of secrets.
```

You should see the words "dozen" and "motives" highlighted in yellow. But now they lack all the interactions which were inherent to the `[url]` tag. If you experiment a little, you may also notice that the `RichTextEffect` class doesn't provide that many options to customize the look of the highlighted word. You can adjust its font, color, offset, or general transform, but you cannot add any extra decorations and flair.

This is not the dead end though. Both interactions and decorations can be solved with standard tools available to all `Control` nodes: input handling via `_gui_input()` and custom drawing via `_draw()`. What `RichTextEffect` is giving us is a way to hook into engine's knowledge about parsed BBcode tags. Using that we can collect details about highlighted words and keep them up to date.

Now, I have to point out that the `RichTextEffect` class is not made for this purpose. It could potentially have some useful hooks to make the following part more straightforward. But right now, it doesn't. What we have at our disposal is just this one method:

```gdscript
func _process_custom_fx(char_data: CharFXTransform) -> bool:
	return true
```

The `_process_custom_fx()` method is called for every character of the string inside of our custom tag. This is done so you can do adjustments to each individual character (think "color the word in rainbow" or "make it do the wave" as an example of that). Furthermore, it is called several time _per rendered line_ of the `RichTextLabel` node (not per line of text). Three times to be exact, because each line is drawn in 3 passes: shadow, outline, color.

The `CharFXTransform` object given to us has some information about the entire affected string, but not enough to read it all at once. So we need to collect this information piece by piece as the method goes through each text character.

Let's get back to our original task: collecting clues from the source text. We create a new class called `SourceClueEffect`, and this is our starting point now:


```gdscript
@tool
class_name SourceClueEffect extends RichTextEffect

var bbcode: String = "clue"


func _process_custom_fx(char_data: CharFXTransform) -> bool:
	_process_clue(char_data)
	
	return true


func _process_clue(char_data: CharFXTransform) -> void:
	pass
```

The approach that we can pick here is pretty straightforward. The `CharFXTransform` object gives us positional information for the character in the source text as well as a relative index within the string inside of the `[clue]` tag.

What we can take from this is that when the relative index becomes `0`, this means we're at the start of a new word, and that when the positional information repeats, this means we're looping and starting to read the same line of the `RichTextLabel` text again.

```gdscript
var _current_clue_index: int = -1
var _current_clue_end: int = -1
var _current_clue_position: Vector2 = Vector2(-1.0, -1.0)


func _process_clue(char_data: CharFXTransform) -> void:
	# Reached a new word and have the previous word collected, reset.
	if char_data.relative_index == 0 && not _current_clue_index == -1:
		print("new clue (%d:%d)" % [ _current_clue_index, _current_clue_end ])
		
		_current_clue_index = -1
		_current_clue_end = -1
		_current_clue_position = Vector2(-1.0, -1.0)
	
	# Starting a new word.
	if char_data.relative_index == 0:
		_current_clue_index = char_data.range.x
		_current_clue_position = char_data.transform.origin
	
	# Always update the end of the currently collected word.
	_current_clue_end = char_data.range.y
```

While doing this you may quickly notice that the method is called constantly. And indeed, `_process_custom_fx()` is being called on every draw call of the owning `RichTextLabel`, and, as I mentioned, 3 times per each drawn line. We only need to extract this information once, as we don't expect it to change dynamically. And even if it did change dynamically, it doesn't make sense to parse the data constantly.

Let's introduce a flag that allows us to trigger this process on demand.

```gdscript
var parsing_clues: bool = false:
	set = set_parsing_clues


func _process_custom_fx(char_data: CharFXTransform) -> bool:
	if parsing_clues:
		_process_clue(char_data)
	
	return true


func set_parsing_clues(value: bool) -> void:
	if parsing_clues == value:
		return
	parsing_clues = value
	
	if parsing_clues:
		_current_clue_index = -1
		_current_clue_end = -1
		_current_clue_position = Vector2(-1.0, -1.0)
```

There is also a simple trick that we can utilize to avoid the 3-times problem. The `CharFXTransform` object contains an `outline` flag, which is set to true for both shadow and outline passes, leaving only the color pass for us to work with.

```gdscript
func _process_clue(char_data: CharFXTransform) -> void:
	if not parsing_clues || char_data.outline:
		return
	
	# Reached a new word and have the previous word collected, reset.
	if char_data.relative_index == 0 && not _current_clue_index == -1:
		print("new clue (%d:%d)" % [ _current_clue_index, _current_clue_end ])
		
		_current_clue_index = -1
		_current_clue_end = -1
		_current_clue_position = Vector2(-1.0, -1.0)
	
	# Starting a new word.
	if char_data.relative_index == 0:
		_current_clue_index = char_data.range.x
		_current_clue_position = char_data.transform.origin
	
	# Always update the end of the currently collected word.
	_current_clue_end = char_data.range.y
```

One small touch remains: we need to inform the `RichTextLabel` about our findings. The print statement in code samples above points to the place where doing so would make sense, so let's quickly swap it for a signal emission. For extra convenience, let's put the necessary code into its own method too.

```gdscript
signal clue_found(from_index: int, to_index: int, position: Vector2)


func _process_clue(char_data: CharFXTransform) -> void:
	if not parsing_clues || char_data.outline:
		return
	
	# Reached a new word and have the previous word collected, reset.
	if char_data.relative_index == 0 && not _current_clue_index == -1:
		_notify_clue_found()
	
	# Starting a new word.
	if char_data.relative_index == 0:
		_current_clue_index = char_data.range.x
		_current_clue_position = char_data.transform.origin
	
	# Always update the end of the currently collected word.
	_current_clue_end = char_data.range.y


func _notify_clue_found() -> void:
	clue_found.emit(_current_clue_index, _current_clue_end, _current_clue_position)
	
	_current_clue_index = -1
	_current_clue_end = -1
	_current_clue_position = Vector2(-1.0, -1.0)
```

Now that we have implemented our effect class, how do we actually interact with it? Let's go back to the `RichTextLabel` node for that. Make sure you have added `SourceClueEffect` to our node's custom effects and our node doesn't have any other effects installed to it.

When a `RichTextLabel` has custom effects installed it is being constantly redrawn by the engine. What we need to collect the data is just one engine tick, or one frame. This means we need to trigger the collection once, then let the drawing happen for one frame, and then stop the collection.

Let's do just that. We find our custom effect in the collection of installed effects and give it a green light as soon as we hit `_ready()`. Then in `_draw()` we check if the collection is enabled and finish it. This works, because `_draw()` is called by the engine _after_ the native implementation. And the native implementation of `RichTextLabel` processes BBcodes as it drawns each line, triggering our custom code in our custom `RichTextEffect`.

So by the time `_draw()` is called in our script — we have already collected all the information.

```gdscript
class_name SourceDocument extends RichTextLabel


func _ready() -> void:
	var source_clue_effect: SourceClueEffect = custom_effects[0]
	source_clue_effect.clue_found.connect(_handle_new_clue)
	source_clue_effect.parsing_clues = true


func _draw() -> void:
	var source_clue_effect: SourceClueEffect = custom_effects[0]
	
	if source_clue_effect.parsing_clues:
		source_clue_effect.parsing_clues = false


func _handle_new_clue(from_index: int, to_index: int, at_position: Vector2) -> void:
	print("new clue (%d:%d)" % [ from_index, to_index ])
```

Let's test this! Our true and trusted text should be as follows now:

```
The cases — there are a [clue]dozen[/clue] — immediately grow more elaborate and intricate, involving more suspects, murkier [clue]motives[/clue], tons of unrelated clues, and plenty of secrets.
```

However, only "dozen" is printed. After a bit of debugging it should be apparent that our logic is a bit faulty. We collect every clue, but we only notify about these clues as we parse through them. And after the final character of the final clue we no longer do the parsing, as our method is no longer being called by the engine.

So we never notify `RichTextLabel` about the final clue. To solve this, let's make sure we always do one last report as we're disabling the collection process by setting `parsing_clues` to `false`. Here's what the setter for this property in `SourceClueEffect` looks like now:

```gdscript
@tool
class_name SourceClueEffect extends RichTextEffect


func set_parsing_clues(value: bool) -> void:
	if parsing_clues == value:
		return
	parsing_clues = value
	
	if parsing_clues:
		_current_clue_index = -1
		_current_clue_end = -1
		_current_clue_position = Vector2(-1.0, -1.0)
	
	if not parsing_clues && not _current_clue_index == -1:
		_notify_clue_found()
```

We can move on to `_handle_new_clue()` now.

This method receives two pieces of the information: the indices of the clue's bounds, and the position of the clue relative to the `RichTextLabel` node in pixels. And what you probably want to have is the word for this clue itself. Furthermore, we still need to figure out a way to restore interactions and perhaps draw a really thick underline. So we need to have not just the position but the entire rectangle for the clue.

Unfortunately, `RichTextLabel` doesn't provide a convenient way to get a substring for the given character indices. Fortunately, it provides a method that returns the entire parsed text as a string, and we can take it from there.

Similarly, we can improvise to get the bounding rectangle for the clue. Internally, the `RichTextLabel` node knows all about the size of its rendered characters. This information is provided by the `TextServer` via `TextLine` and `TextParagraph` classes. But, we don't have access to the underlying `TextLine` and `TextParagraph` instances of the node.

What we can do is reproduce the results with our own `TextLine` instance. All we need is the text itself, which we just extracted, and the exact font and font size that is used by our `RichTextLabel`, which we can easily read from the theme. And here we go, we now have the exact area for each clue within the `RichTextLabel` node. Just take note that the position that we receive in here is not of the top-left corner but of the baseline for the given text. So to have a proper bounding rectangle we need to do a simple subtraction.


```gdscript
class_name SourceDocument extends RichTextLabel

var _clues_text_buffer: TextLine = TextLine.new()


func _handle_new_clue(from_index: int, to_index: int, at_position: Vector2) -> void:
	var clue_text := get_parsed_text().substr(from_index, to_index - from_index)
	
	_clues_text_buffer.clear()
	_clues_text_buffer.add_string(clue_text, get_theme_font("normal_font"), get_theme_font_size("normal_font_size"))
	
	var clue_rect := Rect2()
	clue_rect.size = _clues_text_buffer.get_size()
	clue_rect.position = at_position - Vector2(0.0, clue_rect.size.y)
	
	pass
```

With this information available you can now do the drawing and interactions you need using standard `Control` API. See the full example of this class in [SourceDocument.gd](gui/components/SourceDocument.gd) that implements all of that.


### Chapter V: Word bank

That was a lot of text, so let's do a smaller step now. The word bank for our collected clues is very simple. All you need is an `HFlowContainer`, a scene with a customized `Label`, and a small script.

First of, make sure that the `Label` scene has its `Mouse Filter` property set to `Pass` or `Stop`. We want these labels to capture mouse events. You may also be interested to know that `Label` nodes have a built-in panel style which you can customize via the theme. So you don't even need any complex layout to give it a background, a border, and a bit of inner padding.

Once you're done with the label, let's move on to the `HFlowContainer` node. Behind the scenes we have a global `Controller` class that acts as a bus between various components in our project. For the purposes of this tutorial it's not particularly interesting, but what's important right now is that it provides a signal for when the clue is selected in one of the source documents, conveniently called `clue_selected`.

The `HFlowContainer` is out word bank class, and what it needs to do is populate itself with clues whenever `Controller` signals about new clues.

```gdscript
class_name WordBank extends HFlowContainer

const ENTRY_SCENE := preload("res://gui/components/WordBankEntry.tscn")

var _clues: PackedStringArray = PackedStringArray()


func _ready() -> void:
	if not Engine.is_editor_hint():
		Controller.clue_selected.connect(_add_selected_clue)


func _add_selected_clue(text: String) -> void:
	if _clues.has(text):
		return
	
	var label := ENTRY_SCENE.instantiate()
	label.text = text
	add_child(label)
	_clues.push_back(text)
```

This is also our entry point into the second part of this tutorial. Clues collected here must be draggable onto the solution. Godot provides a very nice drag'n'drop system within it's GUI implementation. Any `Control` node can be the source of a drag action and the target. Can be both, can be either, depending on your needs.

The drag'n'drop system allows you to associate some object with the drag event, which is what you use to decide whether your target node can/should receive the drop or not. This data can be any Godot object, and the most simple example could be a dictionary with some keys and values. But it can also be a custom class, which gives you type safety and code completion. This is what we're going to use in this case.

We also can benefit from a side feature of the drag'n'drop system. When the drag action is created, we can set a preview, which can be any `Control` node or scene. Conveniently, we can instantiate the same scene we use for the label and set it up with the same data, and it will look like you're just dragging the same node.

Finally, the drag'n'drop system supports forwarding, where you can let one node handle drag and drop logic on behalf of another node. There isn't any particular benefit to it in our case, but we can encapsulate all the logic in the same script if we do that. So we use forwarding too.

The changes to our word bank script look like this then:

```gdscript
func _add_selected_clue(text: String) -> void:
	if _clues.has(text):
		return
	
	var label := ENTRY_SCENE.instantiate()
	label.text = text
	add_child(label)
	
	label.set_drag_forwarding(
		_get_clue_drag_data.bind(text),
		Callable(),
		Callable()
	)
	
	_clues.push_back(text)


func _get_clue_drag_data(_at_position:Vector2, text: String) -> Variant:
	var data := WordBankDragData.new()
	data.value = text
	
	var preview := ENTRY_SCENE.instantiate()
	preview.text = text
	set_drag_preview(preview)
	
	return data


class WordBankDragData:
	var value: String = ""
```

With this done you should be able to click and drag entries from the word bank. We just need to build a target for them.


### Chapter VI: Solving blanks

In the game you have a document that summarizes the results of your investigation. It describes the events in order, the perpetrator and the victim, and some other important details. Except, you don't have all the information present in this document, and instead the key points in it are left blank. You must drag the clues collected from before in these blank places to complete the document, as the game validates the correctness of your conclusions. All blanks of the same type are presented with an equal size to avoid giving up the information by the shape of the blank alone.

This is what is left for us to implement. Let's assume for the purposes of this tutorial that there is only one type of clues and blanks.

At this point you actually have all the details you need to figure out most of this final part. You can start from the same basic setup we used for the clues. The `RichTextLabel`, the custom tag, collecting words inside of these tags — the works.

You can then use the collected data, the bounding rectangles of the words in blanks to implement the other part of the drag'n'drop system so we can receive clues as guesses. It can look something like this:

```gdscript
class_name DossierDocument extends RichTextLabel


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if data is not WordBank.WordBankDragData:
		return false
	
	for blank_data in _blanks:
		if blank_data.rect.has_point(at_position):
			return true
	
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if data is not WordBank.WordBankDragData:
		return
	
	for blank_data in _blanks:
		if blank_data.rect.has_point(at_position):
			var text_value := (data as WordBank.WordBankDragData).value
			blank_data.set_assigned_text(text_value)
			break


class DossierBlank:
	var rect: Rect2 = Rect2()
	var _assigned_text: String = ""
	
	
	func set_assigned_text(value: String) -> void:
		if _assigned_text == value:
			return
		
		_assigned_text = value
```

Two problems though: how do we check the results, and — and this is critical — the blanks aren't actually blank right now! Isn't much of a puzzle if the answer is already written in, I agree.

Let's go back to the custom effect tag to figure this problem out. So, assuming you have copied over the implementation from our first effect class and then gave it a different name, you should have a tag that looks like this when used in practice:

```
The Case of the Golden Idol is a [blank]detective[/blank] [blank]point-and-click[/blank] game by [blank]Color[/blank] [blank]Gray[/blank] Games, featuring a [blank]dozen[/blank] of murderous [blank]scenarios[/blank].
```

We want to replace each word with an empty panel. Each panel should have the same size, so all blanks looks the same. When a clue is guessed the blank should display that clue's value on top of the empty panel.

To hide the text you can give it a transparent color in the effect's code (after all, recoloring characters is what the effect is for in the first place). There is also the `visible` property on the `CharFXTransform` object that you can change. Both of these options simply make the characters invisible, but the word inside of the tag still takes the space. And, crucially, it takes the exact amount of space that the word needs, potentially spoiling the solution.

The only way to completely hide the text is to remove it from the tag's content. You see, tags also support arguments. You can specify various configuration options this way, and custom tags support arguments too. You set arguments via the opening half of the tag. Each argument must have a name and a value, separated by `=`.

So in our case it can look like this:

```
The Case of the Golden Idol is a [blank hint=detective][/blank] [blank hint=point-and-click][/blank] game by [blank hint=Color][/blank] [blank hint=Gray][/blank] Games, featuring a [blank hint=dozen][/blank] of murderous [blank hint=scenarios][/blank].
```

When we parse the blanks in the effect code, we can read these values and pass them on alongside other information that we collect.

```gdscript
@tool
class_name DossierBlankEffect extends RichTextEffect

signal blank_found(from_index: int, to_index: int, value: String, position: Vector2)


func _process_blank(char_data: CharFXTransform) -> void:
	if not parsing_blanks || char_data.outline:
		return
	
	if char_data.relative_index == 0 && not _current_blank_index == -1:
		_notify_blank_found()
	
	if char_data.relative_index == 0:
		_current_blank_index = char_data.range.x
		_current_blank_value = char_data.env["hint"]
		_current_blank_position = char_data.transform.origin
	_current_blank_end = char_data.range.y


func _notify_blank_found() -> void:
	blank_found.emit(_current_blank_index, _current_blank_end, _current_blank_value, _current_blank_position)
	
	_current_blank_index = -1
	_current_blank_end = -1
	_current_blank_value = ""
	_current_blank_position = Vector2(-1.0, -1.0)
```

You can even go fancy and support multiple hinted options using a string with a separator. Just be careful which separator you use, because comma (`,`) is automatically treated as an array separator and your value is automatically converted into an array. If you want type safety, you probably don't want that.

```
The Case of the Golden Idol is a [blank hint=detective;point-and-click][/blank] [blank hint=detective;point-and-click][/blank] game.
```

But now, the blanks are completely invisible, nothing is drawn there. Sadly, I didn't find any solution that can allowed us to insert some space on the fly. You can, of course, return to the brute force approach that we discussed before and pre-process the text in some way. I went in another direction.

What `RichTextLabel` nodes can also do is display images. And there isn't a distinction in Godot between something that is conventionally considered an image and just any other kind of texture resource, including a custom one. In other words, we can insert any texture into the text using the `[img]` tag:

```
[img]res://gui/theme/blanks/blue_blank_texture.tres[/img]
```

Now, how exactly you create this texture is entirely up to you. For my own convenience I made a custom texture class that renders a `StyleBoxFlat` resource (see [StyleTexture.gd](gui/components/StyleTexture.gd)). This allowed me to define this texture parametrically. But in practice you'll probably have something premade as one of your assets.

I know, this is pretty verbose and reduces the readability of the text property if edited directly without any assisting tools. At this point you will probably have to make some kind of WYSIWYG editor for your level designers to circumvent this problem. You also need to be careful about changing these paths, but this is true for any resource embedding in `RichTextLabel` texts.

This is what the text will look like with all these changes. For brevity I renamed the argument from "hint" to "?".


```
The Case of the Golden Idol is a [blank ?=detective;point-and-click][img]res://gui/theme/blanks/blue_blank_texture.tres[/img][/blank] [blank ?=detective;point-and-click][img]res://gui/theme/blanks/blue_blank_texture.tres[/img][/blank] game by [blank ?=Color][img]res://gui/theme/blanks/blue_blank_texture.tres[/img][/blank] [blank ?=Gray][img]res://gui/theme/blanks/blue_blank_texture.tres[/img][/blank] Games, featuring a [blank ?=dozen][img]res://gui/theme/blanks/blue_blank_texture.tres[/img][/blank] of murderous [blank ?=scenarios][img]res://gui/theme/blanks/blue_blank_texture.tres[/img][/blank].
```

Now that we have this texture in place, some adjustments are required for the bounding rectangle computation. Instead of using the size of the shaped text directly, we can rely on the texture size.

The texture is vertically centered against the text by default, so we need to using the ascent and descent of the line to properly shift the bounding rectangle around in our math. Our given position, once again, is of the baseline. The ascent is the height of the line above the base line, and the descent is the height below it.

```gdscript
@tool
class_name DossierDocument extends RichTextLabel

const BLUE_BLANK_TEXTURE := preload("res://gui/theme/blanks/blue_blank_texture.tres")


func _handle_new_blank(from_index: int, to_index: int, blank_text: String, at_position: Vector2) -> void:
	_blanks_text_buffer.clear()
	_blanks_text_buffer.add_string(blank_text, get_theme_font("normal_font"), get_theme_font_size("normal_font_size"))
	
	var blank_rect := Rect2()
	blank_rect.size = BLUE_BLANK_TEXTURE.get_size()
	blank_rect.position = at_position
	blank_rect.position.y -= (_blanks_text_buffer.get_line_ascent() - _blanks_text_buffer.get_line_descent() + blank_rect.size.y) / 2.0
	
	var blank_data := DossierBlank.new()
	blank_data.allowed_text = blank_text.split(";", false)
	blank_data.rect = blank_rect
	blank_data.span = Vector2i(from_index, to_index)
	
	_blanks.push_back(blank_data)
```

To render the assigned clue we need to create `TextLine` text buffers for each blank and update them when the assigned value changes. We then use these buffers to render the text using the bounding rectangle from the calculations above.

```gdscript
func _draw() -> void:
	_process_blanks()
	
	var blank_color := get_theme_color("default_color")
	
	for blank_data in _blanks:
		if blank_data.text_buffer:
			var label_position := blank_data.rect.position
			label_position += (blank_data.rect.size - blank_data.text_buffer.get_size()) / 2.0
			
			blank_data.text_buffer.draw(get_canvas_item(), label_position, blank_color)


class DossierBlank:
	var allowed_text: PackedStringArray = PackedStringArray()
	var rect: Rect2 = Rect2()
	var span: Vector2i = Vector2i(-1, -1)
	
	var _assigned_text: String = ""
	var text_buffer: TextLine = TextLine.new()
	
	
	func is_assigned_valid() -> bool:
		return _assigned_text in allowed_text
	
	
	func set_assigned_text(value: String, font: Font, font_size: int) -> void:
		if _assigned_text == value:
			return
		
		_assigned_text = value
		text_buffer.clear()
		text_buffer.add_string(_assigned_text, font, font_size)
```

And with that, you have all the basics done for this mechanic!


### The Epilogue

I hope this tutorial hasn't been too heavy on you. I wanted to walk you through the development of a feature such as this and how you could approach the task. Because it's not the code that really matters, it's the approach and the search for solutions, sometimes workarounds or hacks, and ultimately for the thing that works for you, so you can be done and move on to the next one.

Feel free to reach out wherever you can find me, if you have any questions! And please consider [supporting my work on Patreon](https://patreon.com/YuriSizov).

Normally, I don't do tutorials, I make tools instead. But sharing my knowledge with the community is important to me, and creating such example projects, writing such articles takes a lot of time. And I want to continue doing this for as long as I can!

Cheers <3
