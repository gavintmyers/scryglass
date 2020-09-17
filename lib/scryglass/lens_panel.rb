# frozen_string_literal: true

module Scryglass
  class LensPanel < Scryglass::ViewPanel
    using ClipStringRefinement
    using AnsilessStringRefinement
    using ArrayFitToRefinement

    private

    def self.lenses
      Scryglass.config.lenses
    end

    def uncut_body_string
      current_lens         = scry_session.current_lens
      current_subject_type = scry_session.current_subject_type
      current_subject      = scry_session.current_ro.current_subject
      ro_has_no_key        = !scry_session.current_ro.key_value_pair?

      return '' if ro_has_no_key && current_subject_type == :key

      lens_id = current_lens % LensPanel.lenses.count
      lens = LensPanel.lenses[lens_id]

      scry_session.current_ro.lens_strings[current_subject_type][lens_id] ||=
        begin
          lens[:lambda].call(current_subject)
        rescue => e
          [e.message, *e.backtrace].join("\n")
        end
    end

    def uncut_header_string
      _screen_height, screen_width = $stdout.winsize
      dotted_line = '·' * screen_width

      [
        current_ro_subheader,
        dotted_line,
        lens_param_subheader,
        dotted_line
      ].join("\n")
    end

    def visible_body_slice(uncut_body_string)
      screen_height, screen_width = $stdout.winsize
      non_header_view_size = screen_height - visible_header_string.split("\n").count

      split_lines = uncut_body_string.split("\n")

      ## Here we cut down the (rectangular) display array in both dimensions (into a smaller rectangle), as needed, to fit the view.
      sliced_lines = split_lines.map do |string|
        ansi_length = string.length - string.ansiless_length # Escape codes make `length` different from display length!
        slice_length = screen_width + ansi_length
        string[current_view_coords[:x], slice_length] || '' # If I don't want to
        #   opacify here, I need to account for nils when the view is fully
        #   beyond the shorter lines.
      end
      sliced_list = sliced_lines[current_view_coords[:y], non_header_view_size]

      sliced_list.join("\n")
    end

    def recalculate_y_boundaries
      self.y_boundaries = 0...(uncut_body_string.count("\n") + 1)
    end

    def recalculate_x_boundaries
      _screen_height, screen_width = $stdout.winsize

      split_lines = uncut_body_string.split("\n")
      length_of_longest_line = split_lines.map(&:length).max || 0
      max_line_length = [length_of_longest_line, screen_width].max

      self.x_boundaries = 0...max_line_length
    end

    def current_ro_subheader
      current_ro = scry_session.current_ro
      user_input = scry_session.user_input

      row_above_string =
        current_ro.next_visible_ro_up.to_s if current_ro.next_visible_ro_up
      row_below_string =
        current_ro.next_visible_ro_down.to_s if current_ro.next_visible_ro_down

      tree_preview_related_commands = ['A', 'B', 'C', 'D',
                                       '@', '.', '(', '*', '|', '-']
      ro_view_label =
        if tree_preview_related_commands.include?(user_input)
          "\e[7mVIEWING:\e[00m" # Color reversed
        else
          'VIEWING:'
        end

      current_ro_window =
                "          #{row_above_string}\n" \
        "#{ro_view_label}  #{current_ro}\n" \
                "          #{row_below_string}"

      current_ro_window
    end

    def lens_param_subheader
      _screen_height, screen_width = $stdout.winsize

      current_lens         = scry_session.current_lens
      current_subject_type = scry_session.current_subject_type
      current_subject      = scry_session.current_ro.current_subject
      user_input           = scry_session.user_input

      lens_count = LensPanel.lenses.count
      lens_id    = current_lens % lens_count
      lens       = LensPanel.lenses[lens_id]

      longest_lens_name_length = LensPanel.lenses.map do |lens|
                                   lens[:name].length
                                 end.max
      lens_type_header_length = 9 + (lens_count.to_s.length * 2)
                                  + longest_lens_name_length
      subject_type_header  = "SUBJECT: #{current_subject_type}".ljust(14, ' ')
      subject_class_header = "   CLASS: #{current_subject.class}"
      lens_type_header     = " LENS #{lens_id + 1}/#{lens_count}: #{lens[:name]}"
                             .ljust(lens_type_header_length, ' ')

      fit_lens_header = [
        subject_type_header, subject_class_header, lens_type_header
      ].fit_to(screen_width)

      if user_input == 'l'
        fit_lens_header[4] = "\e[7m#{fit_lens_header[4]}" # Format to be ended by Hexes.opacify_screen_string() (using \e[00m)
      elsif user_input == 'L'
        fit_lens_header[0] = "\e[7m#{fit_lens_header[0]}\e[00m"
      end

      fit_lens_header.join('')
    end
  end
end
