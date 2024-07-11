module ApiHelper
  def display_thumbnail_based_on_locale(comic, locale = I18n.locale)
    thumbnail = comic.comic_images.find_by_language(locale)
    return unless thumbnail

    rails_blob_url(thumbnail.image)
  end

  def display_chapter_based_on_locale(chapter, locale = I18n.locale)
    content = chapter.chapter_contents.find_by_language(locale)
    return unless content

    rails_blob_url(content.image)
  end
end
