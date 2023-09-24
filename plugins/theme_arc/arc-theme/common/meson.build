foreach variant : get_option('variants')
  index_theme = configure_file(
    input: 'index.theme.in',
    output : 'index.theme.' + variant,
    configuration : {
      'variant_name' : variant_name.get(variant),
    }
  )

  install_data(
    index_theme,
    rename: 'index.theme',
    install_dir : prefix / install_dir.get(variant),
  )
endforeach

common_dirs = {
  'gtk2' : 'gtk-2.0',
  'gtk3' : 'gtk-3.0',
  'gtk4' : 'gtk-4.0'
}

foreach theme : get_option('themes')
  subdir(common_dirs.get(theme))
endforeach
