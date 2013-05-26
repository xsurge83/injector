createInstance = (target, args) ->
  F = ->
    target.apply @, args

  F:: = target::
  new F(args)

###
* todo: 
* - cache reflection for next process
###
Injector =

  ###
  * {name, object, selfDeps}
  ###
  dependencies : {}

  parseArgs : (target) -> 
    FN_ARGS = /^function\s*[^\(]*\(\s*([^\)]*)\)/m
    FN_ARG_SPLIT = /,/
    FN_ARG = /^\s*(_?)(\S+?)\1\s*$/
    STRIP_COMMENTS = /((\/\/.*$)|(\/\*[\s\S]*?\*\/))/g
    text = target.toString().replace(STRIP_COMMENTS, '')
    args = text.match(FN_ARGS)[1].split(FN_ARG_SPLIT)
    args
  
  process: (target) ->
    args = @parseArgs(target)
    #instance = target.apply target, @getDependencies(args)
    instance = createInstance target, @getDependencies(args)
    return instance
  getDependencies: (arr) ->
    self = this
    deps = arr.map (value) ->
      dep = self.dependencies[value]
      curTarget = dep.object
      if dep.selfDeps 
        deps = self.getDependencies(dep.selfDeps)
        curTarget = curTarget.apply curTarget, deps 
      curTarget
    deps 

  ###
  * register component 
  * @param {String} name - name of the param used to inject the component 
  # @param {Function} dependencyObj - function to inject
  # @param {bool} - inject component dependencies 
  ###
  register: (name, dependencyObj, injectDeps) ->
    dependency =
      object : dependencyObj
    dependency.selfDeps = @parseArgs dependencyObj if injectDeps
    @dependencies[name] = dependency
  


WelcomeController = (Greeter) ->
  console.log Greeter.greet()

LogController = (log)-> 
  runLog : (value)-> 
    log(value) 

RobotGreeter = greet: ->
  "Domo Arigato"

OtherGreeter = greet: ->
  "That will do pig."

# ## use case 2: second level dependenceis 
# Injector.register 'logController',  LogController
# Injector.process FancyController 

## use case 1 : simple 
# Randomly register a different greeter to show that WelcomeController is truly dynamic.
console.log "USE CASE 1 : SIMPLE"
Injector.register 'log', console.log 
Injector.register "Greeter", (if Math.random() > 0.5 then RobotGreeter else OtherGreeter)

Injector.process WelcomeController

logController = Injector.process LogController
console.log logController
logController.runLog('prime') 

console.log "USE CASE 2 : dependencies"
FancyController = (log)-> 
  logSomething : (value) -> 
    log(value)

SomeController = (fancyController)-> 
  log : (value) ->
    fancyController.logSomething(value)

class MyService 
  constructor:(@log)->
  runLog:(value)-> 
    @log(value)

console.log "USE CASE 3 : class "
Injector.register 'fancyController', FancyController, true 
someController = Injector.process SomeController 
someController.log('testing')

myService = Injector.process MyService 
myService.runLog('myService')








