class Ability
  include CanCan::Ability

  def initialize(user)

    user ||= User.new

    # STEP permissions: user can only create, update, and destroy steps belonging
    # to a project they've authored

    can :create, Step do |step|
        step.project.users.include? user
    end

    can :update, Step do |step|
        (step.project.users.include? user) || user.admin?
    end
    
    can :destroy, Step do |step|
        step.project.users.include? user
    end

    can :update_ancestry, Step do |step|
        (step.project.users.include? user) || user.admin?
    end

    can :read, Project do |project|
        if (project.users.include? user) || (!project.private?) || (user && user.admin?)
            Rails.logger.debug("can read")
            can :read, :all
        end
    end

    # PROJECT permissions: user can only update and destroy projects they've authored
    # user can only add or remove users if they're an author on the project
    can :update, Project do |project|
        project.users.include? user || user.admin?
    end

    can :destroy, Project do |project|
        project.users.include? user
    end

    can :add_users, Project do |project|
        project.users.include? user
    end

    can :remove_user, Project do |project|
        project.users.include? user
    end

    can :categorize, Project do |project|
        project.users.include? user
    end

    can :create_branch, Project do |project|
        project.users.include? user
    end

    can :timemachine, Project do |project|
        project.users.include?(user) || user.admin?
    end

    # USER permissions: user can only edit their own profile
    can :edit_profile, User do |current_user|
        user == current_user
    end

    can :update, User do |current_user|
        user == current_user
    end

    # COLLECTIFY permissions: user can only remove projects from collections they've created
    can :destroy, Collectify do |collectify|
        (collectify.collection.try(:user) == user) || (collectify.project.users.include? user)
    end

    # COLLECTION permissions: user can only edit and destroy collections they've created
    can :update, Collection do |collection|
        collection.user == user
    end

    can :destroy, Collection do |collection|
        collection.user == user
    end

    can :edit, Collection do |collection|
        collection.user == user
    end

    # IMAGE persmissions: users can only edit images from projects they are an author of
    can :destroy, Image do |image|
        image.project.users.include? user
    end

    can :create, Image do |image|
        image.project.users.include? user
    end

    # VIDEO permissions: user can only edit videos for projects they are an author of
    can :create, Video do |video|
        video.project.users.include? user
    end

    can :destroy, Video do |video|
        video.project.users.include? user
    end

    # DESIGN FILE permissions: user can only edit design files for projects they are an author of
    can :create, DesignFile do |designfile|
        designfile.project.users.include? user
    end

    can :destroy, DesignFile do |designfile|
        designfile.project.users.include? user
    end

    # SOUND permissions: user can only edit sounds for projects they are an author of
    can :create, Sound do |sound|
        sound.project.users.include? user
    end

    can :destroy, Sound do |sound|
        sound.projects.users.include? user
    end

    # COMMENT permissions: user can only delete comments they've created
    can :destroy, Comment do |comment|
        comment.user == user
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
