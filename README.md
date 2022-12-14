# 🔮 Scryglass [![Gem Version](https://badge.fury.io/rb/scryglass.svg)](https://badge.fury.io/rb/scryglass)

Scryglass is a ruby console tool for visualizing and actively exploring objects (large, nested, interrelated, or unfamiliar). You can navigate nested arrays, hashes, instance variables, ActiveRecord
relations, and unknown Enumerable types like an expandable/collapsable file tree in an intuitive UI.

Objects and child objects can also be inspected through a variety of display lenses, returned directly to the console, and more!

`scry` is quick to use and useful for both experienced developers and those very new to ruby, rails, or coding.  
It facilitates:
- Debugging/Investigating
- Education, learning the structure of objects and their relationships
- Comparing/Scanning sub-items in an Enumerable (e.g. Person.first.library_records.scry)


# Table of Contents

[🔮 Scryglass Intro Summary](#-scryglass)
- [⚡️ tl;dr SUPER Quick Start](#%EF%B8%8F-tldr-super-quick-start)
- [Installing Scryglass](#installing-scryglass)
- [Enabling Scryglass](#enabling-scryglass)
- [Launching a Scry Session](#launching-a-scry-session)
- [Basic Usage](#basic-usage)
- [Reading the UI](#reading-the-ui)
  - [Tree View (default) Row Sample Strings](#tree-view-default-row-sample-strings)
  - [Known Enumerables](#known-enumerables)
  - [The Cursor, and Unknown Enumerables](#the-cursor-and-unknown-enumerables)
  - [Waiting!](#waiting)
- [In-Depth Control Rundown](#in-depth-control-rundown)
- [Configuration / Customization (all optional)](#configuration--customization-all-optional)
  - [A Note on Adding Your Own Lenses](#a-note-on-adding-your-own-lenses)
  - [Controlling How Some Objects Are Displayed in Tree View / Using Scryglass as the UI for Another Tool](#controlling-how-some-objects-are-displayed-in-tree-view--using-scryglass-as-the-ui-for-another-tool)
- [Miscellaneous Troubleshooting Notes](#miscellaneous-troubleshooting-notes)
- [Contributing](#contributing)


## ⚡️ tl;dr SUPER Quick Start

If you're in a real hurry to get your hands in it (though not necessarily in the most efficient way), here are the quickest steps!

| Quick Step                              | Alternative         |
|-----------------------------------------|------------------------------------------------------|
| 1. **Install:** Add to your Gemfile        | *(OR `gem install scryglass`)*                    |
| 2. **Enable in console:** `Scryglass.load` | *(Please consider adding to `.irbrc` & `.pryrc`)* |
| 3. **Run in console:** `my_object.scry`    | *(OR `scry my_object`)*                           |
| 4. **You're there! Use arrow keys,** and use '?' To learn more. |                              |

## Installing Scryglass

Add the following, with whatever version specifics you like, to your Gemfile, if you use Bundler:
```ruby
gem 'scryglass'
```
And then execute:
```
$ bundle install
```
If you don't have a Gemfile, you can simply install from RubyGems:
```
$ gem install scryglass
```
## Enabling Scryglass

For the `scry` method syntax to work as cleanly as it does, Scryglass needs to add the method to the Kernel module. While this is safe, it was safest to have this only happen on a console session basis. To enable the `scry` method, call `Scryglass.load`. Thus, to automatically enable Scryglass when opening a console, you add one of the following lines to your `./.irbrc` (and `./.pryrc` for rails or pry sessions):
```ruby
Scryglass.load
```
...Which will print the success or failure of loading Scryglass, along with a note of which file loaded it, or
```ruby
Scryglass.load_silently
```
...Which will never print anything upon loading the tool.

And then you're good to go – the syntax is loaded!

## Launching a `scry` Session
In console (Ruby||Rails), you can get some help information with `Scryglass.help`.
Among other things, it will tell you:
```
[...]

To start a Scry Session, call:
>   scry my_object   OR
>   my_object.scry

[...]
```
**A note about passing an argument without parentheses:**  
> The arg syntax (`scry my_object`) will get confused if it's given a hash direcly (`scry {a: [1, 2] }`), thinking you're trying to pass a block, unless you use parentheses (`scry({a: [1, 2] })`).

## Basic Usage

Use the arrow keys to move around and open/close known Enumerable types! Hit `'?'` to view all the controls and learn how to do much much more.

## Reading the UI

Every object (or key-value pair) is one row. Nested objects will be displayed under their parent object, with one more layer of indentation. The cursor will generally look like a horizontal line.

This default view is the Tree View. You can seitch between that and Lens View with `SPACEBAR`.

### Tree View (default) row sample strings
Each row has either an object or a key-value pair. The objects are given a sample representation in the Tree View using `inspect`, and long ones are cut off and marked with `'……'`. For display purposes, newlines (`"\n"`) are removed from these strings, but remain untouched on the object, including in Lens View.

### Known Enumerables
If the object (or the value in a key-value pair) is one of the known Enumerable types, it will display with one of the following wrappers:  

| Wrapper | Indicates... |
|:-------:|--------------|
| `[]` | Array |
| `{}` | Hash |
| `<>` | ActiveRecord Relation *(if ActiveRecord is being used)* |
| `‹›` | ActiveRecord CollectionProxy *(if ActiveRecord is being used)* |

The known Enumerable will also indicate its state:  
| Wrapper | Indicates... |
|:-------:|--------------|
| `[]` | Empty |
| `[•••]` | Closed with hidden contents |
| `[` | Open |

However, some objects (both known and unknown Enumerable types) have sub-items that can be calculated and opened on the spot.

### The Cursor, and Unknown Enumerables
The cursor, movable by arrow keys, is represented by a straight line (`––––`). It may overlap with a selection marker (`->`), if the current row is also a selected row. The left two characters of the cursor serve as gentle indicators of how objects of an unknown Enumerable type might be opened:

| Cursor | The smart opener detects... |
|:------:|-----------------------------|
| `––––` | ...no secret contents |
| `(–––` | ...a non-empty Enumerable of an unknown type (openable with `'('`) |
| `–@––` | ...instance variables on the object (openable with `'@'`) |
| `––·–` | ...ActiveRecord associations (openable with `'.'`) |
| `(@·–` | ...all three! (Note: ***Generally* IVs yield more sub-items with more info than using `'('`).** |

An `X` in place of any of these characters indicates an error or a timeout (if the "counting" process takes longer than 0.05 seconds)

A single `•` will mark the presence of user-added rows when they are hidden.

### Waiting!
Scryglass has two features to make wait time a little easier:
- If any process (with a couple exceptions for user input) takes longer than 4 seconds between you pressing a key and the process completing, it **makes a beep sound!** This means if something seems like it might take a bit, you can switch to another tab or window without worry, and it will tell you when to check back.
- While there are no time estimates (for a number of reasons), many subprocesses are linked to a **progress bar**, which will display at the bottom of the screen. If multiple nested processes are running one within another, the progress bar will divide itself into parts to show each process. The leftmost bar is the base level iteration task.

## In-Depth Control Rundown

| Key | Help_Screen_Snippet | Verbose Description |
|:---:|---------------------|---------------------|
| `?` | Press '?' for controls | `?` will cycle through the help panels, then back to the scry session. |
| `q` | Quit Scry | Exits the scry session, returning nil. The cursor (and exit message) is then placed below the last line console line with content in order to take up no more space than needed. |
| `UP`/`DOWN` | Navigate (To move further, type a number first or use SHIFT) | Moves the cursor one step upward or downward in the tree view (this can be done while in lens view). If a number (of any number of digits) is typed out before pressing `UP` or `DOWN`, then the cursor will move that many steps in that direction. If `SHIFT` is held while pressing, then the cursor will move 12 steps in that direction. If the number of steps goes past the edge of the list, the cursor will sit safely at that edge. |
| `RIGHT` | Expand current or selected row(s) | If any rows are *selected* this attempts to expand all of them, and will expand the ones it can. If none are selected, then it will attempt to expand the current row where the cursor is. If the current row has preexisting sub-items, but they are hidden because the current row is collapsed, this will reveal them in the tree view. |
| `LEFT` | Collapse current or selected row(s) | If any rows are *selected* this attempts to collapse all of them, and will collapse the ones it can. If none are selected, then it will attempt to collapse the current row where the cursor is. If the current row either has no sub-items or is already collapsed, this action will collapse its parent row instead and place the cursor there. |
| `h`/`j`/`k`/`l` | (These keys on the home row can also serve as arrow keys) | This is for those familiar with VIM keybindings! Shift speeds up k/j to 12 steps just the same as UP/DOWN. |
| `ENTER` | Close Scry, returning current or selected object(s) (Key or Value) | Returns the subject object (based on current subject type, :value or :key) of the current item, or, if any items are selected (`->`), it returns all of those in an array. The order matches the order in which they were marked as selected. In the case of \| and \*, the order of the array will be top to bottom. If the current Subject Type (toggled by `L`) is :key, rows without "keys" will return `nil`. |
| `SPACEBAR` | Toggle Lens View | Switches between Tree View and Lens View. This will not change the view position of the lens view, but the view position of the tree view will still follow the cursor if the cursor moves while in lens view. |
| `>` | Cycle through lens types | Cycles through the different lens types in the lens view. These all take the current row, at either the "key" or the "value" object depending on the current subject type (toggled by `L`), and display a string of it, transformed through that particular lens. New lenses can be written in the config. |
| `<` | Toggle subject  (Key/Value of row) | This change is only perceptible in the lens view, but does also change which objects are returned by `ENTER`. Any objects without "keys" will return nil for their :key if they don't have one. |
| `w`/`a`/`s`/`d` | Move view window (ALT increases speed) | The W/A/S/D keys form a second set of arrow keys for moving around the "screen" through which you view the tree view and the lens view, when the contents don't all fit on the screen at once. They move 5 cells in the specified direction, or 50 if ALT is held before pressing. Can be held down for continuous movement. |
| `0` | Reset view location (Press again: reset cursor) | This resets/zeros the current view (tree or lens). If you are in the tree view, and the view is in the zero (top left) position, then this will instead move the cursor there. |
| `@` | Build instance variable sub-rows for current or selected row(s) | Identifies all instance variables on the object (or value of a key-value pair) of the current or selected rows. Then these instance variables are turned into a list of keys, called on the original object, and then paired with the resulting objects. Known Enumerables are recursively navigable as always. |
| `.` | Build ActiveRecord association sub-rows for current or selected row(s) | If the `ActiveRecord` constant is not defined by the system, this will do nothing. If it is, this will navigate the reflections of the the class of the object (or value of a key-value pair) in order to find its AR Associations and turn them into key-value sub-items. Note: With the default configuration, the way it uses reflections *purposefully ignores `:through` relations and `scope`d relations (e.g. the extraneous `CURRENT_phone_numbers`).* Note: The `·` cursor indicator does not take the time to traverse all reflections, nor account for all configured filters. It's possible that `.` will produce no sub-rows despite the indicator. |
| `(` | Attempt to smart-build sub-rows for current or selected row(s), if Enumerable. Usually '@' is preferable | Attempts a "smart reading" of the object (or value of a key-value pair) of the current or selected rows. If the object is an Enumerable, it will attempt to parse it into sub-items. if the object has keys, it will be parsed as key-value pairs like a hash, otherwise singular objects like an array. This can sometimes create sub-items that would otherwise be more neatly accesible under a single instance variable if instance variables are built instead, so default to trying that first. |
| `o` | Quick Open: builds the most likely helpful sub-rows ( '.' \|\| '@' \|\| '(' ) | "Quick Open" first tries opening AR Associations. If none are produced, it tries for instance variables. If none are produced, it attempts to open as it would an unknown Enumerable type. Can be pressed repeatedly to produce all types of sub-rows. |
| `c` | Enter method text to call on object(s), results becomes navigable sub-rows | The text is eval'd, and allows formats like (obj)`.count(nil)` & (obj)`[:test].select { |s| s.include?(@named_string) }`. The execution CAN be used to mutate/destroy objects, though the rows representing those objects, and lenses which were already loaded for it, won't change (this is available but not formally supported). |
| `*` | Select/Deselect ALL rows | This includes hidden rows. If all rows are already selected, they will be unselected, regardless of how they became selected. |
| `\|` | Select/Deselect every sibling row under the same parent row | If all siblings under that parent row are already selected, they will be unselected, regardless of how they became selected. |
| `-` | Select/Deselect current row | If these objects are later returned, the order in which they were selected will determine their order in the returned array. |
| `Tab` | Change session tab (to the right) (`Shift`+`Tab` moves left) | Changes which scry session is the current one, and brings up the tab bar for a couple seconds. |
| `Q` | Close current session tab | Permanently exits the current session tab, but keeps scry running if another tab remains. Switches one tab to left if there is one. |
| `t` | Open new session tab with current or selected row(s) as the seed | The seed subject of the tab will either be the current row's subject or an array of the selected rows' subjects. |
| `T` | Restart session tab with current or selected row(s) as the seed | This will delete the current session tab and replace it. The seed subject of the new tab will either be the current row's subject or an array of the selected rows' subjects. This can be useful for managing memory load. |
| `/` | Begin a text search (in tree view) | Begins a case-sensitive regex search of all items, in a loop, starting with just below the current row. For a matching object to be found, the search must match its *truncated sample string in tree view* (regardless of what is on or off screen) (it must match either the key or the value, not the full line they create) (known enumerable types, like `[•••]`, may count as a match if they contain the string in the backend). |
| `n` | Move to next search result | Will, using the most recent search entry, move the cursor on to the next match downward, cycling through all rows. This follows the same matching rules as the original search. |
| `=` | Open prompt to type a console handle for current or selected row(s) | Gets text from user (not including the '@') and saves the current subject, or array of selected row(s) subjects, under that instance variable name. These variables live in the console itself: the binding of wherever `scry` was called. Care is taken not to allow them to conflict with preexisting IV names or method names. Note: But still, if you are prying inside an object/context, your IVs will be defined on that object. Note: If you switch from one pry context to another and then back, your first pry's instance variables will be there despite not being listed in the IV outro message. |
| `Esc` | Resets selection, last search, and number-to-move. (or returns to Tree View) | (Essentially, clears the values represented in the Tree View header if you're in the Tree View; otherwise it returns you to the Tree View) |

## Configuration / Customization (all optional)

Scry is (optionally) configured with a `configure` method on the `Scryglass` module, allowing you to overwrite default attributes of the Config object, like so:
```ruby
Scryglass.configure do |config|
  config.tab_length = 3
  # config... etc
end
```
This can be placed in any loaded path of your system, including `.irbrc` and `.pryrc`, or directly into the ruby||rails console itself to quickly experiment with settings. But the ideal place for it in an application is likely your own `config/initializers/scryglass.rb` or `config/scryglass.rb`.

Here is a commented-out config file template (you can uncomment and alter things as you wish):  
(Found in *example_config.rb*)  
```ruby
Scryglass.configure do |config|
  ## Display
  # config.tab_length = 2 # Default: 2
  # config.tree_view_key_string_clip_length = 200 # Default: 200
  # config.tree_view_value_string_clip_length = 500 # Default: 500
  # config.dot_coloring = true # Default: true

  ## UX
  # config.cursor_tracking = [:flexible_range, :dead_center][0] # Default: [0]
  # config.lenses = [ # Custom lenses can easily be added as name+lambda hashes! Or comment some out to turn them off.
  #   { name: 'Amazing Print (`ap`)',
  #     lambda: ->(o) { Hexes.capture_io(char_limit: 20_000) { ap o } } }, # This has colors!
  #   { name: 'Pretty Print (`pp`)',
  #     lambda: ->(o) { Hexes.capture_io(char_limit: 20_000) { pp o } } },
  #   { name: 'Inspect (`.inspect`)',
  #     lambda: ->(o) { Hexes.capture_io(char_limit: 20_000) { puts o.inspect } } },
  #   { name: 'Yaml Print (`y`)',
  #     lambda: ->(o) { Hexes.capture_io(char_limit: 20_000) { require 'yaml' ; y o } } }, # OR: `puts o.to_yaml`
  #   { name: 'Puts (`puts`)',
  #     lambda: ->(o) { Hexes.capture_io(char_limit: 20_000) { puts o } } },
  #   { name: 'Method Showcase',
  #     lambda: ->(o) { Scryglass::LensHelper.method_showcase_for(o, char_limit: 20_000) } },
  # ]

  ## AmazingPrint defaults, if the user has not set their own:
  # AmazingPrint.defaults ||= {
  #   index: false,  # (Don't display array indices).
  #   raw:   true,   # (Recursively format instance variables).
  # }
  # See https://github.com/amazing-print/amazing_print


  ## Building ActiveRecord association sub-rows:
  # config.include_empty_associations = true # Default: true
  # config.include_through_associations = false # Default: false
  # config.include_scoped_associations = false # Default: false
  # config.show_association_types = true # Default: true
end
```

If you ever wish to restore the "factory" default config settings for a particular console session, you can run:
```ruby
Scryglass.reset_config
```

Here are some explanations of some less obvious configurations:  
`show_association_types`, when true, will show association types indicators:  
`(HM)` : has_many  
`(HO)` : has_one  
`(BT)` : belongs_to

`(t)` : `:through` (if through relations are enabled)  
`(s)` : `scoped` (if scoped relations are enabled)

### A note on adding your own lenses

For properly capturing out*put* methods of various kinds, and for the ability to truncate strings of cosmic scale before they've been *entirely* printed to the invisible IO (can be minutes and trillions of characters), we highly recommend using the `Hexes.capture_io` method with the `char_limit:` keyword argument as seen in the template config file (and Scryglass code). `capture_io` captures console output as a string; `char_limit:` will run the capture in a separate thread which can be truncated before it finishes printing.

### Controlling how some objects are displayed in tree view / Using Scryglass as the UI for another tool

Scryglass originally started as a small subtool to be used as the UI for another console project, which, in short, would output a large branching hash which was then to be navigated. To have more control over the tree panel display, you can wrap objects in a Scryglass::ViewWrapper. For example, by default, this array item: `[unsightly_object]` will appear in the tree view in its `inspect`ed form, "#<UnsightlyObject:0x00007f9ac8224e78>". But say you want it to show it's best face to the user, using the sightly return of it's `best_face` method. You can instead hand scryglass the following item:
```ruby
Scryglass::ViewWrapper.new(unsightly_object,
                           string: unsightly_object.best_face)
```
Scryglass will use the original object as usual in every way, except the tree view will display it according to your nicer string:
```
[
  Unsightly Object (id:55)
```
This can be used for "key" objects in your hashes just as easily. For example, Scryglass itself, when generating instance variable subitems, uses the following ViewWrapper to make them display a little more naturally, without the colon:
```ruby
iv_key = Scryglass::ViewWrapper.new(iv_name,
                                    string: iv_name.to_s) # to_s removes ':'
```
So
```
:@attributes : {...}
```

becomes, just in the tree view:
```
@attributes : {...}
```
And if it's useful, a `string_lambda:` argument can be passed instead, and the string will be generated once from the lambda, in context, when the session is first built.

## Miscellaneous troubleshooting notes:

If you ever use the search function (`'/'`), press enter, and the only thing that happens is you add a `'^M'` to your entry text: Go back to your shell and run:
```
$ stty sane
```
Or you can try from your ruby console:
```
system('stty sane')
```
And that should do the trick.

## Contributing

Scryglass is being released as a relatively mature piece of software, with smaller improvements to be made over time. As such, we're not looking for contributors at the moment. However:
- Please feel free to use a fork and modify it to your heart's content!
- Please feel free to open a github issue for any problems you run into, or any ideas for possible improvements!
