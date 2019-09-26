-- External dependencies
local lfs = require("lfs")
local json = require("dkjson")

-- Internal modules
local FluentSyntax = require("fluent.syntax")

local function filetostring (fname)
  local f = assert(io.open(fname, "rb"))
  local content = f:read("*all")
  f:close()
  return content
end

describe('upstream reference fixture', function ()
  local syntax = FluentSyntax()

  local fixtures_dir = lfs.currentdir() .. "/spec/fixtures/"
  for object in lfs.dir(fixtures_dir) do
    local fname = fixtures_dir .. object
    if fname:match(".ftl$") and (
        false
        or fname:match("/any_char.ftl$")
        -- or fname:match("/astral.ftl$")
        -- or fname:match("/callee_expressions.ftl$")
        -- or fname:match("/call_expressions.ftl$")
        or fname:match("/comments.ftl$")
        or fname:match("/cr.ftl$")
        -- or fname:match("/crlf.ftl$")
        or fname:match("/eof_comment.ftl$")
        or fname:match("/eof_empty.ftl$")
        -- or fname:match("/eof_id_equals.ftl$")
        -- or fname:match("/eof_id.ftl$")
        -- or fname:match("/eof_junk.ftl$")
        or fname:match("/eof_value.ftl$")
        -- or fname:match("/escaped_characters.ftl$")
        or fname:match("/junk.ftl$")
        -- or fname:match("/leading_dots.ftl$")
        or fname:match("/literal_expressions.ftl$")
        -- or fname:match("/member_expressions.ftl$")
        -- or fname:match("/messages.ftl$")
        -- or fname:match("/mixed_entries.ftl$")
        -- or fname:match("/multiline_values.ftl$")
        -- or fname:match("/numbers.ftl$")
        or fname:match("/obsolete.ftl$")
        -- or fname:match("/placeables.ftl$")
        -- or fname:match("/reference_expressions.ftl$")
        -- or fname:match("/select_expressions.ftl$")
        -- or fname:match("/select_indent.ftl$")
        -- or fname:match("/sparse_entries.ftl$")
        or fname:match("/tab.ftl$")
        -- or fname:match("/term_parameters.ftl$")
        -- or fname:match("/terms.ftl$")
        or fname:match("/variables.ftl$")
        -- or fname:match("/variant_keys.ftl$")
        or fname:match("/whitespace_in_value.ftl$")
        or fname:match("/zero_length.ftl$")
      ) then
      describe(object, function ()
        local ftl = filetostring(fname)
        local jsonref = filetostring(fname:gsub(".ftl$", ".json"))
        local reference = json.decode(jsonref)

        local resource

        it('test should have a reference', function()
          assert.equal("table", type(reference))
        end)

        it('should parse without blowing up', function ()
          assert.no.error(function () resource = syntax:parsestring(ftl) end)
        end)

        it('should have a Resource as the AST root', function ()
          assert.equal("Resource", resource.type)
        end)

        it('should match the referece result', function ()
          assert.same(reference, resource:dump_ast())
        end)

      end)
    end
  end

end)

describe('upstream structure fixture', function ()
  local syntax = FluentSyntax()

  local fixtures_dir = lfs.currentdir() .. "/spec/structure/"
  for object in lfs.dir(fixtures_dir) do
    local fname = fixtures_dir .. object
      if fname:match(".ftl$") and (
        false
        or fname:match("/attribute_expression_with_wrong_attr.ftl")
        -- or fname:match("/attribute_of_private_as_placeable.ftl")
        or fname:match("/attribute_of_public_as_selector.ftl")
        -- or fname:match("/attribute_starts_from_nl.ftl")
        -- or fname:match("/attribute_with_empty_pattern.ftl")
        -- or fname:match("/attribute_without_equal_sign.ftl")
        -- or fname:match("/blank_lines.ftl")
        or fname:match("/broken_number.ftl")
        -- or fname:match("/call_expression_errors.ftl")
        or fname:match("/comment_with_eof.ftl")
        -- or fname:match("/crlf.ftl")
        -- or fname:match("/dash_at_eof.ftl")
        -- or fname:match("/elements_indent.ftl")
        or fname:match("/empty_resource.ftl")
        or fname:match("/empty_resource_with_ws.ftl")
        -- or fname:match("/escape_sequences.ftl")
        -- or fname:match("/expressions_call_args.ftl")
        -- or fname:match("/indent.ftl")
        or fname:match("/junk.ftl")
        -- or fname:match("/leading_dots.ftl")
        or fname:match("/leading_empty_lines.ftl")
        or fname:match("/leading_empty_lines_with_ws.ftl")
        or fname:match("/message_reference_as_selector.ftl")
        -- or fname:match("/message_with_empty_multiline_pattern.ftl")
        -- or fname:match("/message_with_empty_pattern.ftl")
        or fname:match("/multiline-comment.ftl")
        -- or fname:match("/multiline_pattern.ftl")
        or fname:match("/multiline_string.ftl")
        -- or fname:match("/multiline_with_non_empty_first_line.ftl")
        -- or fname:match("/multiline_with_placeables.ftl")
        -- or fname:match("/non_id_attribute_name.ftl")
        -- or fname:match("/placeable_at_eol.ftl")
        -- or fname:match("/placeable_at_line_extremes.ftl")
        -- or fname:match("/placeable_in_placeable.ftl")
        or fname:match("/placeable_without_close_bracket.ftl")
        or fname:match("/resource_comment.ftl")
        or fname:match("/resource_comment_trailing_line.ftl")
        -- or fname:match("/second_attribute_starts_from_nl.ftl")
        or fname:match("/select_expressions.ftl")
        or fname:match("/select_expression_without_arrow.ftl")
        or fname:match("/select_expression_without_variants.ftl")
        or fname:match("/select_expression_with_two_selectors.ftl")
        or fname:match("/simple_message.ftl")
        -- or fname:match("/single_char_id.ftl")
        or fname:match("/sparse-messages.ftl")
        or fname:match("/standalone_comment.ftl")
        or fname:match("/standalone_identifier.ftl")
        -- or fname:match("/term.ftl")
        or fname:match("/term_with_empty_pattern.ftl")
        or fname:match("/unclosed_empty_placeable_error.ftl")
        -- -- or fname:match("/unclosed.ftl") -- see https://github.com/projectfluent/fluent/issues/296
        or fname:match("/unknown_entry_start.ftl")
        or fname:match("/variant_ends_abruptly.ftl")
        -- or fname:match("/variant_keys.ftl")
        -- or fname:match("/variant_starts_from_nl.ftl")
        or fname:match("/variants_with_two_defaults.ftl")
        -- or fname:match("/variant_with_digit_key.ftl")
        -- or fname:match("/variant_with_empty_pattern.ftl")
        -- or fname:match("/variant_with_leading_space_in_name.ftl")
        or fname:match("/variant_with_symbol_with_space.ftl")
        -- or fname:match("/whitespace_leading.ftl")
        -- or fname:match("/whitespace_trailing.ftl")
      ) then
      describe(object, function ()
        local ftl = filetostring(fname)
        local jsonref = filetostring(fname:gsub(".ftl$", ".json"))
        local reference = json.decode(jsonref)

        local resource

        it('should have a reference', function()
          assert.equal("table", type(reference))
        end)

        it('should parsestring without blowing up', function ()
          assert.no.error(function () resource = syntax:parsestring(ftl) end)
        end)

        it('should have a Reference as the AST root', function ()
          assert.equal("Resource", resource.type)
        end)

        it('should match the referece result', function ()
          assert.same(reference, resource:dump_ast())
        end)

      end)
    end
  end

end)
