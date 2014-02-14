CKEDITOR.editorConfig = (config) ->
  config.startupShowBorders = true
  config.resize_enabled = false
  config.scayt_autoStartup = true

  config.language = 'en'
  config.width = '445px'

  config.toolbar_Default = [
    { name: 'basicstyles', items: [ 'Bold','Italic','Underline', '-', 'NumberedList','BulletedList', 'Link','Unlink', 'RemoveFormat' ] }
  ]
  config.toolbar = 'Default'
  true