module MINT
  # TASK MODEL


  # A {Task} defines the basic control flow object, has a {#parent} task, unless it's the root task and a textual,
  # unstructured {#description}.
  #
  class Task < Interactor
    #    belongs_to :parent, "Task"
    property :description, Text

    def initialize_statemachine
      if @statemachine.nil?

        @statemachine = Statemachine.build do
          trans :initialized, :run, :running
          trans :running, :stop, :done
        end
      end
    end
  end


# Each {InteractionTask} is linked to one abstract interaction container
# {MINT::AIContainer}
#
  class InteractionTask < Task
    #   has 1, :AIContainer @TODO - Mappings unklar
    belongs_to :pts, "PTS"
  end

# An {ApplicationTask} is completely executed by the computer without any human intervention
# through it's internal processing. An {ApplicationTask} can generate or manipulate
# Domain objects through it's internal processing. The {ApplicationTask} is used to model service
# calls to the functional core of the application or it can enable other {Task}s if it is used to model
# sensor information.
#
  class ApplicationTask < Task

  end

# {InputInteractionTask}s describe {Task}s realizing some interaction techniques to enable the user
# interacting with the system. {InputInteractionTask}s include selecting objects, editing data or enabling the
# user to control some actions explicitly through events. If an {InputInteractionTask} is  marked as synchronous
# it has to contain at least one control object that the user can issue to proceed the {Task}.
#
  class InputInteractionTask < InteractionTask
  end

# {OutputInteractionTask}s present information to the user. This could be raw structured data like documents or tables
# or multimedia output such as video or sound. [OutputInteractionTask}s read the objects that are associated with
# the task once if the are marked as synchronous or until they get disabled by another {ApplicationTask}'s or an
# {InputInteractionTask} if they are marked as asynchronous.
#
  class OutputInteractionTask < InteractionTask
  end

# A Presentation Task set {PTS} contains a set of active interaction tasks that should be presented or manipulated by the
# user
#
  class PTS < Interactor
    def initialize_statemachine
      if @statemachine.nil?
        @statemachine = Statemachine.build do
          trans :initialized, :calculate, :calculating
          trans :calculating, :done, :finished
        end
      end
    end
  end
end