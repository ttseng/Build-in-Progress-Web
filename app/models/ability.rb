class Ability
  include CanCan::Ability

  def initialize(user)
    can :read, :all

    # STEP permissions: user can only create, update, and destroy steps belonging
    # to a project they've authored
    can :create, Step do |step|
        step.project.users.include? user
    end

    can :update, Step do |step|
        step.project.users.include? user
    end
    
    can :destroy, Step do |step|
        step.project.users.include? user
    end

    # PROJECT permissions: user can only update and destroy projects they've authored
    can :update, Project do |project|
        project.users.include? user
    end

    can :destroy, Project do |project|
        project.users.include? user
    end

    # User permissions: user can only edit their own profile
    can :edit_profile, User do |current_user|
        user == current_user
    end

    # COLLECTION permissions: user can only remove projects from collections they've created
    can :destroy, Collectify do |collectify|
        collectify.collection.try(:user) == user
    end

    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user 
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. 
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
end
