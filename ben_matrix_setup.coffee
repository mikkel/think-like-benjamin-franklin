Priorities = new Meteor.Collection("priorities")
Answers = new Meteor.Collection("answers")
Questions = new Meteor.Collection("questions", 
  transform: (doc) -> 
    new Question(doc)
)

Router.map ->
  this.route 'home', path: '/'
  this.route 'questionsShow', 
    path: '/questions/:_id',
    data: ->
      Questions.findOne(this.params._id)

if (Meteor.isClient) 
  window.Priorities = Priorities
  window.Answers = Answers
  window.Questions = Questions
  class Question
    constructor: (x) ->
      @name = x.name
      @id = x._id
    priorities: ->
      Priorities.find({question_id: @id})
    answers: ->
      Answers.find({question_id: @id})

    default_value: ->
      50

    answer_name: ->
      result = Answers.findOne({question_id: @id}, {sort: {score: -1}})
      
      if result && result.score
        result.name
      else
        "Undecided"
    calculate_scores: ->
      @answers().forEach (answer) =>
        total_score = 0
        @priorities().forEach (priority) =>
          answer.answer_priorities ||= {}
          
          score = answer.answer_priorities[priority._id] 
          if(!score)
            score = @default_value
          
          score = parseInt(score)
          pvalue = priority.value
          if(!pvalue)
            pvalue = @default_value
          total_score += parseInt(pvalue) * score
        if(parseInt(answer['score']) != total_score)
          answer['score']= total_score
          Answers.update(answer._id, answer)
    prioritized_answers: ->
      Answers.find({question_id: @id}, {sort: {score: -1}})


  editOrUpdate = (e, klass, opts) ->
    el = $(e.currentTarget)
    opts["name"] = el.val()
    klass.update(opts._id, opts)

  Template.user_data.questions = ->
    if(Meteor.user())
      Questions.find({user_id: Meteor.user()._id})
    else
      Questions.find({user_id: null})
  Template.priorities.events = 
    'click input[type="range"]': (e) ->
      t = $(e.currentTarget)
      id = t.attr("id")
      val = t.val()
    'click input[type="button"][data-crud="create"]': (e) ->
      Priorities.insert({question_id: this._id, name: "New Priority"})
    'click input[type="button"][data-crud="delete"]': (e) ->
      Priorities.remove({_id: this._id})
    'change .priority[data-crud="update"]': (e) ->
      editOrUpdate(e, Priorities, { _id: this._id, question_id: this.question_id})
    'change .priority[type="range"]': (e) ->
      obj = Priorities.findOne(this._id)
      val = $(e.currentTarget).val()
      obj["value"] = val
      Questions.find().forEach (question) ->
        question.calculate_scores()
      Priorities.update(this._id, obj)
  Template.answers.events =
    'click input[type="button"][data-crud="create"]': (e) ->
      Answers.insert({question_id: this._id, name: "New Answer" })
    'click input[type="button"][data-crud="delete"]': (e) ->
      Answers.remove({_id: this._id})
    'change .answer[data-crud="update"]': (e) ->
      editOrUpdate(e, Answers, { _id: this._id, question_id: this.question_id})
    'change .answer[type="range"]' : (e) ->
      answer_id = $(e.currentTarget).attr('data-answer')
      priority_id = $(e.currentTarget).attr('data-priority')
      obj = Answers.findOne(answer_id)
      val = $(e.currentTarget).val()
      obj["answer_priorities"] ||= {}
      obj["answer_priorities"][priority_id] = val
      Answers.update(answer_id, obj)
      
      Questions.find().forEach (question) ->
        question.calculate_scores()

  Template.user_data.events = 
    'click input.question[type="button"][data-crud="create"]': (e) ->
      user_id = null
      user_id = Meteor.user()._id if Meteor.user()
      q = Questions.insert({name: "New Question", user_id: user_id})
      Router.go('questionsShow', {_id: q})
  Template.questionsShow.events = 
    'change .question[data-crud="update"]': (e) ->
      user_id = null
      user_id = Meteor.user()._id if Meteor.user()
      editOrUpdate(e, Questions, { _id: this._id, user_id: user_id })

  Template.answers.display_answer_priorities = ->
    priorities = Priorities.find({question_id: this.question_id})
    response = ""
    answer_id=this._id
    answer_priorities = this.answer_priorities || {}
    priorities.forEach (priority) ->
      priority_id=priority._id
      value = answer_priorities[priority_id]

      response += """<td>
        <input data-answer="#{answer_id}" data-priority="#{priority_id}" type="range" class="answer" min="1" max="100" value="#{value}">
      </td>"""
    response

if (Meteor.isServer) 
  Meteor.startup ->

