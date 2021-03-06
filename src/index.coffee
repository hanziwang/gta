exports = exports or this

class Gta

  constructor: (options) ->
    @options = options
    @providers = {}
    for provider, option of options
      Provider = Gta["#{provider[0].toUpperCase()}#{provider[1..]}"]
      @providers[provider] = new Provider(option) if Provider?
    @delegateEvents() if window.jQuery

  pageview: ->
    for name, provider of @providers
      provider.pageview.apply(provider, arguments)
    return this

  event: ->
    for name, provider of @providers
      provider.event.apply(provider, arguments)
    return this

  delegateEvents: ->
    $(document).on('click.gta', '[data-gta="event"]', (e) =>
      $target = $(e.currentTarget)
      category = $target.data('category') or $target[0].tagName
      label = $target.data('label') or $target[0].className
      action = $target.data('action') or e.type
      value = $target.data('value') or $target.html()
      useMixpanel = not not $target.data('useMixpanel')
      @event(category, action, label, value, useMixpanel)
    )

  @appendScript: (script) ->
    dom = document.createElement('script')
    text = document.createTextNode(script)
    dom.appendChild(text)
    head = document.getElementsByTagName('head')[0]
    head.appendChild(dom)

  class @Base

    constructor: (option) ->
      @option = option
      @option.account = option.account or ''
      @_initial()

  class @Google extends @Base

    constructor: (option) ->
      super

    _initial: ->
      unless window.ga?
        Gta.appendScript("""
          (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
          (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
          m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
          })(window,document,'script',('https:'===window.location.protocol?'https:':'http:') + '//www.google-analytics.com/analytics.js','ga');
          ga('create', '#{@option.account}');
          ga('send', 'pageview');
        """)
      return window.ga

    pageview: ->
      args = (val for i, val of arguments)
      data = if typeof args[0] == 'object' then args[0] else args.join('_')
      window.ga?('send', 'pageview', data)

    event: ->
      args = (val for i, val of arguments)
      window.ga?('send', 'events', args)

  class @Baidu extends @Base

    constructor: (option) ->
      super

    _initial: ->
      unless window._hmt?
        Gta.appendScript("""
          var _hmt = _hmt || [];
          (function() {
            var hm = document.createElement("script");
            hm.src = ('https:'===window.location.protocol?'https:':'http:') + "//hm.baidu.com/hm.js?#{@option.account}";
            var s = document.getElementsByTagName("script")[0];
            s.parentNode.insertBefore(hm, s);
          })();
        """)
      return window._hmt

    pageview: ->
      args = (val for i, val of arguments)
      if typeof args[0] == 'object'
        if args[0]['page']?
          data = args[0]['page']
        else
          data = for i, v of args[0]
            v
          data = data.join('_')
      else
        data = args.join('_')
      window._hmt?.push(['_trackPageview', data])

    event: ->
      args = (val for i, val of arguments)
      data = ['_trackEvent'].concat(args)
      window._hmt?.push(data)

  class @Mixpanel extends @Base

    constructor: (options) ->
      super

    _initial: ->
      unless window.Mixpanel
        Gta.appendScript("""
          (function(e,b){if(!b.__SV){var a,f,i,g;window.mixpanel=b;a=e.createElement('script');a.type='text/javascript';a.async=!0;a.src=('https:'===e.location.protocol?'https:':'http:')+'//cdn.mxpnl.com/libs/mixpanel-2.2.min.js';f=e.getElementsByTagName('script')[0];f.parentNode.insertBefore(a,f);b._i=[];b.init=function(a,e,d){function f(b,h){var a=h.split('.');2==a.length&&(b=b[a[0]],h=a[1]);b[h]=function(){b.push([h].concat(Array.prototype.slice.call(arguments,0)))}}var c=b;'undefined'!==
          typeof d?c=b[d]=[]:d='mixpanel';c.people=c.people||[];c.toString=function(b){var a='mixpanel';'mixpanel'!==d&&(a+='.'+d);b||(a+=' (stub)');return a};c.people.toString=function(){return c.toString(1)+'.people (stub)'};i='disable track track_pageview track_links track_forms register register_once alias unregister identify name_tag set_config people.set people.set_once people.increment people.append people.track_charge people.clear_charges people.delete_user'.split(' ');for(g=0;g<i.length;g++)f(c,i[g]);
          b._i.push([a,e,d])};b.__SV=1.2}})(document,window.mixpanel||[]);
          mixpanel.init('#{@option.account}');
        """)

      return window.mixpanel

    pageview: ->
      # Mixpanel does not support pageview

    event: (category, action, label, value, useMixpanel=false)->
      useMixpanel and mixpanel.track(arguments[2])

exports.Gta = Gta
