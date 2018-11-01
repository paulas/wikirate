# ~~~~~~~~ Handling of Unknown Checkbox ~~~~~~~~~~~~~~~~

decko.slotReady (slot) ->
  slot.find(".RIGHT-unknown input[type=checkbox]").on "change", ->
    if $(this).is(":checked")
      clearAnswerValue $(this).slot()

  slot.find(".RIGHT-value").find("input,select").on "change", () ->
    updateUnknownness(slot, $(this))

clearAnswerValue = (slot) ->
  editor = slot.find ".card-editor.RIGHT-value .content-editor"
  clearValue editor

clearValue = (editor) ->
  select = editor.find "select"
  if (select[0])
    select.val(null).change()
  else
    clearInputValue editor

clearInputValue = (editor) ->
  input = editor.find("input:not(.current_revision_id)")
  if input.prop("type") == "text"
    input.val null
  else
    input.prop "checked", false

updateUnknownness = (slot, value_input)->
  unknown_checkbox = slot.find(".RIGHT-unknown input[type=checkbox]")
  $(unknown_checkbox).prop 'checked', isUnknown(value_input.val())

isUnknown = (value)->
  value.toLowerCase() == 'unknown'

# ~~~~~~~~ Other Research Page Handling ~~~~~~~~~~~~~~~~

decko.slotReady (slot) ->
# autocomplete tag on research (new/Answer) page
  $('input._research-select').autocomplete
    select: (e, ui) ->
      $target = $(e.target)
      url = $target.data("url")
      url += (if url.match /\?/ then '&' else '?')
      url += $target.data("key") + "=" + encodeURIComponent(ui.item.value)
      $target.updateSlot(url)

  # company, metric, and year dropdowns on research page
  $("._html-select").each ->
    $(this).select2
      minimumInputLength: 0
      #minimumResultsForSearch: 4
      maximumSelectionSize: 1
      dropdownAutoWidth: "true"
      width: "130%"
      templateResult: formatHtmlOptionItem
      templateSelection: formatHtmlSelectedItem
      escapeMarkup: (markup) ->
        markup
      containerCssClass: "html-select2"
      dropdownCssClass: "html-select2"

  $("._html-select").on "select2:select", (event) ->
    url = $(event.params.data.element).data("url")
    window.location = decko.path(url)

  $("body").on "click", "._methodology-tab", ->
    $('a[href="#research_page-methodology"]').tab("show")

formatHtmlOptionItem = (i) ->
  if i.loading
    return i.text
  selector = $(i.element).data("option-selector")
  $(selector).html()

formatHtmlSelectedItem = (i) ->
  selector = $(i.element).data("selected-option-selector")
  $(selector).html()

$(document).ready ->
  $("#main:has(>#Research_Page.slot_machine-view)").addClass("pl-0 pr-0")

  # add related company to name
  # otherwise the card can get the wrong type because it
  # matches the ltype_rtype/record/year pattern
  $("body").on "submit", "form.answer-form", (e) ->
    $form = $(e.target)
    related_company = $form.find("#card_subcards__related_company_content")
    if related_company.length == 1
      name = $form.find("#card_name").val()
      $form.find("#card_name").val(name + "+" + related_company.val())
      unless $form.find("#success_id").val() == ":research_page"
        $form.find("#success_id").val("_left")
