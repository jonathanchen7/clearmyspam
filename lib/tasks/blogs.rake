namespace :blogs do
  desc "Extract data from blog markdown files and save to database"
  task sync_metadata: :environment do
    blog_files = Dir.glob(Rails.root.join("app/views/blogs/*.md"))

    # Keep track of processed slugs
    processed_slugs = []

    blog_files.each do |file|
      slug = File.basename(file, ".md")
      processed_slugs << slug

      # Read the first few lines to extract metadata
      # This assumes all blogs have a title, subtitle, and date
      # like "Title: My Blog Title" at the top of the file
      content = File.read(file)

      # Parse title from first h1
      title = content.match(/^#\s+(.+)/)&.[](1) || slug.titleize

      # Parse date from first h5
      date_string = content.match(/^#####\s+(.+)/)&.[](1)
      published_at = Date.parse(date_string)

      # Parse subtitle from first h6
      subtitle = content.match(/^######\s+(.+)/)&.[](1)

      # Parse tag from first comment
      tag = content.match(/^<!--\s*tags:\s*(.+)\s*-->/)&.[](1)

      blog = Blog.find_or_initialize_by(slug: slug)
      blog.update!(
        title: title,
        subtitle: subtitle,
        tag: tag,
        published_at: published_at
      )

      puts "Saved metadata for blog: #{slug}"
    end

    # Delete blogs that don't have corresponding markdown files
    blogs_to_delete = Blog.where.not(slug: processed_slugs)
    blogs_to_delete.destroy_all
  end
end
