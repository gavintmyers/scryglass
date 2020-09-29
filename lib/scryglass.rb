# frozen_string_literal: true

## Bookkeeping
require "scryglass/version"

## External tools:
require 'io/console'
require 'stringio'
require 'pp'
require 'amazing_print' # For use as a lens
require 'method_source' # For use in lens_helper
require 'binding_of_caller'
require 'timeout'

## Refinements and sub-tools:
require 'refinements/ansiless_string_refinement'
require 'refinements/clip_string_refinement'
require 'refinements/constant_defined_string_refinement'
require 'refinements/array_fit_to_refinement'
require 'scryglass/lens_helper'
require 'hexes'
require 'prog'

## Core gem components:
require 'scryglass/config'
require 'scryglass/ro'
require 'scryglass/ro_builder'
require 'scryglass/session'
require 'scryglass/view_wrapper'
require 'scryglass/view_panel'
require 'scryglass/tree_panel'
require 'scryglass/lens_panel'
require 'scryglass/binding_tracker'

## Testing and Demoing:
require 'example_material.rb'

module Scryglass
  HELP_SCREEN = <<~'HELPSCREENPAGE'
          q : Quit Scry                               ? : Cycle help panels (1/2)

    BASIC NAVIGATION: · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·
      ·                                                                               ·
      ·   UP / DOWN : Navigate (To move further, type a number first or use SHIFT)    ·
      ·   RIGHT     : Expand   current or selected row(s)                             ·
      ·   LEFT      : Collapse current or selected row(s)                             ·
      ·                                                                               ·
      ·               (h/j/k/l  on the home row can also serve as arrow keys)         ·
      ·                                                                               ·
      ·   ENTER : Close Scry, returning current or selected object(s) (Key or Value)  ·
      ·                                                                               ·
      · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·

    INSPECTING WITH LENS VIEW:  · · · · · · · · · · · · · ·
      ·                                                   ·
      ·   SPACEBAR : Toggle Lens View                     ·
      ·        >   : Cycle through lens types             ·
      ·      <     : Toggle subject  (Key/Value of row)   ·
      ·                                                   ·
      · · · · · · · · · · · · · · · · · · · · · · · · · · ·

    MORE NAVIGATION:  · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·
      ·                                                                       ·
      ·      [w]    :  Move view window           0 : Reset view location     ·
      ·   [a][s][d]   (ALT increases speed)      (Press again: reset cursor)  ·
      ·                                                                       ·
      · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·
  HELPSCREENPAGE

  HELP_SCREEN_ADVANCED = <<~'HELPSCREENADVANCEDPAGE'
          q : Quit Scry                               ? : Cycle help panels (2/2)

    ADVANCED: · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·
      ·  DIGGING DEEPER:                                                                    ·
      ·    For current or selected row(s)...                                                ·
      ·      @ : Build instance variable sub-rows                                           ·
      ·      . : Build ActiveRecord association sub-rows                                    ·
      ·      ( : Attempt to smart-build sub-rows, if Enumerable. Usually '@' is preferable. ·
      ·      o : Quick Open: builds the most likely helpful sub-rows ( '.' || '@' || '(' )  ·
      ·                                                                                     ·
      ·  SELECTING ROWS:                                                                    ·
      ·    * : Select/Deselect ALL rows                                                     ·
      ·    | : Select/Deselect every sibling row under the same parent row                  ·
      ·    - : Select/Deselect current row                                                  ·
      ·                                                                                     ·
      ·  TEXT SEARCH:                                                                       ·
      ·    / : Begin a text search (in tree view)                                           ·
      ·    n : Move to next search result                                                   ·
      ·                                                                                     ·
      ·                                                                                     ·
      ·  ' : Open prompt to type a console handle for current or selected row(s)            ·
      ·                                                                                     ·
      ·  Esc : Resets selection, last search, and number-to-move. (or returns to Tree View) ·
      ·                                                                                     ·
      · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·
  HELPSCREENADVANCEDPAGE

  def self.config
    @config ||= Config.new
  end

  def self.reset_config
    @config = Config.new
  end

  def self.configure
    yield(config)
  end

  def self.load_silently
    begin
      add_kernel_methods
      { success: true, error: nil }
    rescue => e
      { success: false, error: e }
    end
  end

  def self.load
    caller_path = caller_locations.first.path

    silent_load_result = Scryglass.load_silently

    if silent_load_result[:success]
      puts "(Scryglass is loaded, from `#{caller_path}`. Use `Scryglass.help` for help getting started)"
    else
      puts "(Scryglass failed to load, from `#{caller_path}` " \
           "getting `#{silent_load_result[:error].message}`)"
    end

    silent_load_result
  end

  def self.help
    console_help = <<~"CONSOLE_HELP" # Bolded with \e[1m
      \e[1m
      |  To prep Scryglass, call `Scryglass.load`
      |  (Or add it to .irbrc & .pryrc)
      |
      |  To start a Scry Session, call:
      |  >   scry my_object   OR
      |  >   my_object.scry
      |
      |  To resume the previous session:   (in same console session)
      |  >   scry   OR
      |  >   scry_resume (if you're in a breakpoint pry)
      \e[0m
    CONSOLE_HELP

    puts console_help
  end

  private

  def self.add_kernel_methods
    Kernel.module_eval do
      def scry(arg = nil, actions = nil)
        # `actions` can't be a keyword arg due to this ruby issue:
        #   https://bugs.ruby-lang.org/issues/8316

        receiver = self unless to_s == 'main'
        # As in: `receiver.scry`,
        #   and no receiver means scry was called on 'main', (unless self is
        #   different in the because you've pry'd into something!)

        seed_object = arg || receiver

        if seed_object
          # We carry on the binding (and user created instance variable list)
          #   of the last scry session if their caller bindings have the same
          #   receiver/self.
          old_binding_tracker = $scry_session&.binding_tracker
          new_binding = binding.of_caller(2)
          binding_tracker =
            if old_binding_tracker&.receiver == new_binding.receiver
              old_binding_tracker
            else
              Scryglass::BindingTracker.new(
                console_binding: new_binding
              )
            end

          # If it's been given an arg or receiver, create new session!
          # The global variable is purposeful, and not accessible outside of
          #   the one particular console instance.
          $scry_session = Scryglass::Session.new(
            seed_object,
            binding_tracker: binding_tracker
          )
        end

        scry_resume(actions) # Pick up the new or previous session
      end

      # For the user, this is mainly just for pry sessions where `self` isn't `main`
      def scry_resume(actions = nil)
        Scryglass.config.validate!

        no_previous_session = $scry_session.nil?
        if no_previous_session
          raise ArgumentError,
                '`scry` requires either an argument, a receiver, or a past' \
                'session to reopen. try `Scryglass.help`'
        end

        begin
          Hexes.stdout_rescue do
            $scry_session.run_scry_ui(actions: actions)
          end
        rescue => e # Here we ensure good visibility in case of errors
          screen_height, _screen_width = $stdout.winsize
          $stdout.write "\e[#{screen_height};1H\n" # (Moves console cursor to bottom left corner)
          raise e
        end
      end
    end
  end
end
