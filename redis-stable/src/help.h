<% title "Help | #{ENV['APP_NAME']}" %>
<div class="fullRow">
    <ul class="nav nav-list">
        <li class="nav-header">PROJECTS</li>
        <li><a href="#create_project">Create a Project</a></li>
        <li><a href="#add_step">Add a Step</a></li>
        <li><a href="#reorder_steps">Reorder Steps</a></li>
        <li><a href="#create_branch">Create a Branch</a></li>
        <li><a href="#create_branch_label">Create a Branch Label</a></li>
        <li><a href="#edit_categories">Edit Categories</a></li>
        <li><a href="#edit_collaborators">Edit Collaborators</a></li>
        <li><a href="#add_design_files">Add Design Files</a></li>
        <li><a href="#ask_a_question">Ask a Question</a></li>
        <li><a href="#embed_project">Embed Your Project</a></li>
        <li><a href="#export_project">Export Your Project</a></li>
        <li><a href="#set_privacy">Set Privacy Settings</a></li>
        <li><a href="#create_remix">Create a Remix</a></li>

        <li class="nav-header">COLLECTIONS</li>
        <li><a href="#create_collection">Create a Collection</a></li>
        <li><a href="#add_project">Add a Project</a></li>
        <li><a href="#set_privacy_collections">Set Privacy Settings</a></li>

        <li class="nav-header">SOCIAL</li>
        <li><a href="#follow_user">Follow a User</a></li>
        <li><a href="#favorite">Favorite</a></li>
        <li><a href="#comment">Comment</a></li>
    </ul>

    <div class="container">
        <h3>Help</h3>   
        <div class="clear"></div>
        <div class="helpText">
            <div class="tabbable">
                <ul class="nav nav-tabs">
                    <li class="tab active"><a href="#projects" data-toggle="tab">Projects</a></li>
                    <li class="tab"><a href="#collections" data-toggle="tab">Collections</a></li>
                    <li class="tab"><a href="#social" data-toggle="tab">Social</a></li>
                </ul>
            </div>
            <div class="tab-content">
                <div class="tab-pane active" id="projects">

                    <div class="instructions" id="create_project">
                        <%= image_tag "help/create_project_static.png", :class=>"help_gif create_project_img" %>
                        <h4>Create a Project</h4>
                        <p>To create a project, click the profile button on the top of the page, and then click "Create Project".</p>
                    </div>

                    <div class="instructions" id="add_step">
                        <%= image_tag "help/add_a_step_static.png", :class=>"help_gif add_a_step_img" %>
                        <h4>Add a Step</h4>
                        <p>To add a step, click the "+" button on the left side of the project page. You can add a name, description, and images and videos to your step. Don't forget to click the "Create Step" to save!
                        </p>
                    </div>

                    <div class="instructions" id="reorder_steps">
                        <%= image_tag "help/reorder_step_static.png", :class=>"help_gif reorder_step_img"%>
                        <h4>Reorder Steps</h4>
                        <p>Click and drag steps to rearrange. Places you can drop a step will be highlighted in blue.</p>
                    </div>

                    <div class="instructions" id="create_branch">
                        <%= image_tag "help/create_branch_static.png", :class=>"help_gif create_branch_img" %>
                        <h4>Create a Branch</h4>
                        <p>To create a branch, drag and drop a step over the step you want it to follow.  
                        </p>
                    </div>

                    <div class="instructions" id="create_branch_label">
                        <%= image_tag "help/create_branch_label_static.png", :class=>"help_gif create_branch_label_img" %>
                        <h4>Create a Branch Label</h4>
                        <p>You can create branch labels to help organize different branches in your project.</p>
                        <p>To create a branch label, click the “A” button on the left of the project page. Select a color for your label, give it a title, and click "Create Label." Drag and drop the label to rearrange.
                        </p>
                    </div>

                    <div class="instructions" id="edit_categories">
                        <%= image_tag "help/edit_categories_static.png", :class=>"help_gif edit_categories_img" %>
                        <h4>Edit Categories</h4>
                        <p>You can add categories to your project to make it easier for others to find. Click the "Add Project Categories" link to select categories for your project.</p>
                    </div>

                    <div class="instructions" id="edit_collaborators">
                        <%= image_tag "help/edit_collaborators_static.png", :class=>"help_gif edit_collaborators_img" %>
                        <h4>Edit Collaborators</h4>
                        <p>To add collaborators to a project, click on the blue collaborators button on your project page. Type the username of the collaborator you would like to add, select the user from the dropdown menu, and click the "Save" button. All collaborators can edit the project directly.</p>
                        <p>To remove collaborators, click the "Edit Collaborators" button and click "remove" next to any user you want to remove.</p>
                    </div>

                    <div class="instructions" id="add_design_files">
                        <%= image_tag "help/add_design_files_static.png", :class=>"help_gif add_design_files_img" %>
                        <h4>Add Design Files</h4>
                        <p>You can upload design files (like CAD files and Arduino or Processing sketches) to your project page. Edit a step and expand the "Manage Design Files" section, where you'll be able to add design files.</p>
                    </div>

                    <div class="instructions" id="ask_a_question">
                        <%= image_tag "help/ask_a_question_static.png", :class=>"help_gif ask_a_question_img" %>
                        <h4>Ask a Question</h4>
                        <p>You can ask for advice on your project by posting a question to a step. Edit a step and expand the "Ask for Advice" section, where you can type in a question to ask. This will create a flag on your project, and your question may also appear directly on the homepage.</p>
                    </div>

                    <div class="instructions" id="ask_a_question">
                        <%= image_tag "help/mark_question_answered_static.png", :class=>"help_gif mark_question_answered_img" %>
                        <p style="margin-top: 38px;">Be sure to mark your question as answered when you've made a decision. Clicking the "answered" box near your question. You will then be directed to the step form, where you can describe what you decided to do.</p>
                    </div>

                    <div class="instructions" id="embed_project">
                        <%= image_tag "help/embed_project_static.png", :class=>"help_gif embed_project_img" %>
                        <h4>Embed Your Project</h4>
                        <p>To grab embed code to share your project on other sites, click the blue share button on the project page and copy the embed code.</p>        
                    </div>

                    <div class="instructions" id="export_project">
                        <%= image_tag "help/export_project_static.png", :class=>"help_gif export_project_img" %>
                        <h4>Export Your Project</h4>
                        <p>To download the images, text, and videos from your project, click the black export button on your project page. This will download a zip file onto your computer with all your documentation.</p>
                    </div>

                    <div class="instructions" id="set_privacy">
                        <%= image_tag "help/set_privacy_static.png", :class=>"help_gif privacy_gif set_privacy_img" %>
                        <h4>Set Privacy Settings</h4>
                        <p>There are three possible privacy settings for your project:
                            <ul>
                                <li><strong>Public</strong>: Your project will be shared with everyone on Build in Progress</li>
                                <li><strong>Unlisted</strong>: Only users with a direct link to your project will be able to see the project.</li>
                                <li><strong>Private</strong>: Only you can view your project</li>
                            </ul>
                            <p>To set the privacy for your project, select from the privacy dropdown menu at the top of your project page.</p>
                        </p>
                    </div>

                    <div class="instructions" id="create_remix">
                        <%= image_tag "help/remix_static.png", :class=>"help_gif remix_img" %>
                        <h4>Create a Remix</h4>
                        <p>A remix is a new project inspired by an existing project on the site.</p>
                        <p>When you click the green remix button on a project page, it will create a remix of the original project that you can edit however you'd like. Your remix becomes public on Build in Progress once you've edited it.</p>
                    </div>
                </div>

                <div class="tab-pane" id="collections">
        
                    <div class="instructions" id="create_collection">
                        <%= image_tag "help/create_collection_static.png", :class=>"help_gif create_collection_img" %>
                        <h4>Create a Collection</h4>
                        <p>To create a collection, click the profile button on the top of the page, and then click "Create Collection".</p>
                    </div>

                    <div class="instructions" id="add_project">
                        <%= image_tag "help/add_project_static.png", :class=>"help_gif add_project_img" %>
                        <h4>Add a Project</h4>
                        <p>To add a project to a collection, enter the project URL and click the "+ Add project" button. Anyone can add a project to a collection, but only the owner of the collection can remove projects.</p>
                    </div>

                    <div class="instructions" id="set_privacy_collections">
                        <%= image_tag "help/set_privacy_collections_static.png", :class=>"help_gif privacy_gif set_privacy_collections_img" %>
                        <h4>Set Privacy Settings</h4>
                        <p>There are three possible privacy settings for your collection:
                            <ul>
                                <li><strong>Public</strong>: Your collection will be shared with everyone on Build in Progress</li>
                                <li><strong>Unlisted</strong>: Only users with a direct link to your collection will be able to see the collection.</li>
                                <li><strong>Private</strong>: Only you can view your collection</li>
                            </ul>
                            <p>To set the privacy for your collection, select from the privacy dropdown menu at the left of your collections page.</p>
                        </p>
                    </div>
                </div>

                <div class="tab-pane" id="social">

                    <div class="instructions" id="follow_user">
                        <%= image_tag "help/follow_static.png", :class=>"help_gif follow_img" %>
                        <h4>Follow a User</h4>
                        <p>If you follow users on Build in Progress, you'll be able to see their project updates on your activity feed (which you can view on the homepage).</p>
                        <p>To follow a user, go to their profile page and click the "follow" button.</p>
                    </div>

                    <div class="instructions" id="favorite">
                        <%= image_tag "help/favorite_static.png", :class=>"help_gif favorite_img" %>
                        <h4>Favorite</h4>
                        <p>To favorite a project, click the star button on the project page.</p>
                    </div>

                    <div class="instructions" id="comment">
                        <%= image_tag "help/comment_static.png", :class=>"help_gif comment_img" %>
                        <h4>Comment</h4>
                        <p>To comment, click a step, type your comment in the comment section, and click the "Comment" button.</p>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script type="text/javascript">
// alternate between static image and gif for different help images
$('.create_project_img').hover(function(){
    $(this).attr('src', '<%= asset_path("help/create_project.gif") %>');
    }, function(){
        $(this).attr('src', '<%= asset_path("help/create_project_static.png") %>');
    });

$('.add_a_step_img').hover(function(){
    $(this).attr('src', '<%= asset_path("help/add_a_step.gif") %>');
    }, function(){
        $(this).attr('src', '<%= asset_path("help/add_a_step_static.png") %>');
    });

$('.reorder_step_img').hover(function(){
    $(this).attr('src', '<%= asset_path("help/reorder_step.gif") %>');
    }, function(){
        $(this).attr('src', '<%= asset_path("help/reorder_step_static.png") %>');   
    });

$('.create_branch_img').hover(function(){
    $(this).attr('src', '<%= asset_path("help/create_branch.gif") %>');
    }, function(){
        $(this).attr('src', '<%= asset_path("help/create_branch_static.png") %>');  
    });

$('.create_branch_label_img').hover(function(){
    $(this).attr('src', '<%= asset_path("help/create_branch_label.gif") %>');
    }, function(){
        $(this).attr('src', '<%= asset_path("help/create_branch_label_static.png") %>');    
    });

$('.edit_categories_img').hover(function(){
    $(this).attr('src', '<%= asset_path("help/edit_categories.gif") %>');
    }, function(){
        $(this).attr('src', '<%= asset_path("help/edit_categories_static.png") %>');    
    });

$('.edit_collaborators_img').hover(function(){
    $(this).attr('src', '<%= asset_path("help/edit_collaborators.gif") %>');
    }, function(){
        $(this).attr('src', '<%= asset_path("help/edit_collaborators_static.png") %>'); 
    });

$('.add_design_files_img').hover(function(){
    $(this).attr('src', '<%= asset_path("help/add_design_files.gif") %>');
    }, function(){
        $(this).attr('src', '<%= asset_path("help/add_design_files_static.png") %>');   
    });

$('.ask_a_question_img').hover(function(){
    $(this).attr('src', '<%= asset_path("help/ask_a_question.gif") %>');
    }, function(){
        $(this).attr('src', '<%= asset_path("help/ask_a_question_static.png") %>'); 
    });

$('.mark_question_answered_img').hover(function(){
    $(this).attr('src', '<%= asset_path("help/mark_question_answered.gif") %>');
    }, function(){
        $(this).attr('src', '<%= asset_path("help/mark_question_answered_static.png") %>'); 
    });

$('.embed_project_img').hover(function(){
    $(this).attr('src', '<%= asset_path("help/embed_project.gif") %>');
    }, function(){
        $(this).attr('src', '<%= asset_path("help/embed_project_static.png") %>');  
    });

$('.export_project_img').hover(function(){
    $(this).attr('src', '<%= asset_path("help/export_project.gif") %>');
    }, function(){
        $(this).attr('src', '<%= asset_path("help/export_project_static.png") %>'); 
    });

$('.set_privacy_img').hover(function(){
    $(this).attr('src', '<%= asset_path("help/set_privacy.gif") %>');
    }, function(){
        $(this).attr('src', '<%= asset_path("help/set_privacy_static.png") %>');    
    });

$('.remix_img').hover(function(){
    $(this).attr('src', '<%= asset_path("help/remix.gif") %>');
    }, function(){
        $(this).attr('src', '<%= asset_path("help/remix_static.png") %>');  
    });

$('.create_collection_img').hover(function(){
    $(this).attr('src', '<%= asset_path("help/create_collection.gif") %>');
    }, function(){
        $(this).attr('src', '<%= asset_path("help/create_collection_static.png") %>');
    });

$('.add_project_img').hover(function(){
    $(this).attr('src', '<%= asset_path("help/add_project.gif") %>');
    }, function(){
        $(this).attr('src', '<%= asset_path("help/add_project_static.png") %>');    
    });

$('.set_privacy_collections_img').hover(function(){
    $(this).attr('src', '<%= asset_path("help/set_privacy_collections.gif") %>');
    }, function(){
        $(this).attr('src', '<%= asset_path("help/set_privacy_collections_static.png") %>');
    });

$('.follow_img').hover(function(){
    $(this).attr('src', '<%= asset_path("help/follow.gif") %>');
    }, function(){
        $(this).attr('src', '<%= asset_path("help/follow_static.png") %>'); 
    });

$('.favorite_img').hover(function(){
    $(this).attr('src', '<%= asset_path("help/favorite.gif") %>');
    }, function(){
        $(this).attr('src', '<%= asset_path("help/favorite_static.png") %>');
    });

$('.comment_img').hover(function(){
    $(this).attr('src', '<%= asset_path("help/comment.gif") %>');
    }, function(){
        $(this).attr('src', '<%= asset_path("help/comment_static.png") %>');
    });

$('li a').click(function(){
    $('li a').removeClass("active");
    $(this).addClass("active");
    var tab_name = $(this).parent().prevAll('.nav-header:first').html().toLowerCase();
    $('.nav-tabs a[href="#'+tab_name+'"]').tab('show');
    var id = $(this).attr('href');
    $(id).animateHighlight('#E7F3FF', 3000);
});

function offsetAnchor() {
    if(location.hash.length !== 0) {
        window.scrollTo(window.scrollX, window.scrollY - 170);
    }
}

$(window).on("hashchange", function () {
    offsetAnchor();
});
</script>