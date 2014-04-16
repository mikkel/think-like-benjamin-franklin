Priorities = new Meteor.Collection("priorities")
Answers = new Meteor.Collection("answers")
Questions = new Meteor.Collection("questions", 
  transform: (doc) -> 
    new Question(doc)
)

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

    calculate_scores: ->
      @answers().forEach (answer) =>
        @priorities().forEach (priority) =>
          #answer.score= Math.rand()
          Answers.update(answer._id, answer)
    prioritized_answers: ->
      @calculate_scores()
      Answers.find({question_id: @id}, {sort: {score: -1}})

  class SampleQuestion extends Question
    current_answer: ->
      for answer in @answers
        range = $("##{answer.name}-points")[0]
      Answers.find({question_id: @id}, {sort: {score: -1}, limit: 1})

  editOrUpdate = (e, klass, opts) ->
    el = $(e.currentTarget)
    opts["name"] = el.val()
    console.log(opts)
    klass.update(opts._id, opts)

  Template.user_data.questions = 
    Questions.find()
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
      console.log("P change")
      obj = Priorities.findOne(this._id)
      val = $(e.currentTarget).val()
      obj["value"] = val
      Priorities.update(this._id, obj)
  Template.answers.events =
    'click input[type="button"][data-crud="create"]': (e) ->
      Answers.insert({question_id: this._id, name: "New Answer"})
    'click input[type="button"][data-crud="delete"]': (e) ->
      Answers.remove({_id: this._id})
    'click td .answer': (e) ->
      console.log($("##{this._id}"))
    'change .answer[data-crud="update"]': (e) ->
      editOrUpdate(e, Answers, { _id: this._id, question_id: this.question_id})
    'change .answer[type="range"]' : (e) ->
      console.log(e)
      answer_id = $(e.currentTarget).attr('data-answer')
      priority_id = $(e.currentTarget).attr('data-priority')
      obj = Answers.findOne(answer_id)
      val = $(e.currentTarget).val()
      obj["answer_priorities"] ||= {}
      obj["answer_priorities"][priority_id] = val
      Answers.update(answer_id, obj)

  Template.user_data.events = 
    'click input.question[type="button"][data-crud="create"]': (e) ->
      Questions.insert({name: "New Question"})
    'change .question[data-crud="update"]': (e) ->
      editOrUpdate(e, Questions, { _id: this._id})

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

