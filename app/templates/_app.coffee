app = angular.module 'tryethereum', ['partials' <%=  ngModules %>]

<% if (ngRoute) { %>
app.config ($routeProvider, $locationProvider) ->
  $routeProvider
    .when '/', 
      templateUrl: '/partials/home.html'
    .otherwise 
      redirectTo: '/'
  $locationProvider
      .html5Mode(false)
  return
<% } %>

<% if (Foundation) { %>
dom = angular.element document
# Manual initialization to run foundation
dom.ready ->
  dom.foundation()
  try
    angular.bootstrap document, ['tryethereum']
  catch err
<% } %>