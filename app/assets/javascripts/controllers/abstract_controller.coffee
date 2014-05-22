###

Abstract

###

class AbstractController

  constructor: (options)->
    @abstractContainer = options.abstractContainer
    do @delegateEvents

  delegateEvents: ->
    terms = '[data-ui-role="meta_term"]'
    
    @abstractContainer.on "mouseenter", terms, (e)=>
      target = $(e.currentTarget)
      target.addClass "mouseenter"
      if target.data("popover")?
        target.popover "show"
      else
        @loadPreview target

    @abstractContainer.on "mouseleave", terms, -> $(this).removeClass "mouseenter"

  loadPreview: (target)->
    filter = {meta_data: {}}
    filter.meta_data[target.data("meta-datum-name")] = {ids: [target.data("meta-key-id")]}
    App.MediaResource.fetch 
      meta_data: filter.meta_data
      per_page: 3
    , (media_resources, response)=>
      content = App.render("abstracts/preview", {mediaResources: media_resources, total: response.pagination.total})
      target.popover
        html: true
        placement: "top"
        trigger: "hover"
        content: content
      target.popover "show" if target.is ".mouseenter"

window.App.AbstractController = AbstractController
