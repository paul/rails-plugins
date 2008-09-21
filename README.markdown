
# Rails Plugins

## Table For 2

A more elegant way to write html tables. A simple example:

    table_for @articles do |t|
      
      # simplest, just puts the results of this attribute in the td
      t.column :title

      # slightly more complicated, passes the results of the attribute into the block
      t.column(:tags) do |tags|
        tags.join(', ')
      end

      # most complicated, allows a great deal of control over the attributes of the column
      t.column do |c|
        c.title = "No. Comments"                # The text in the table header
        c.cell_attributes[:class] << 'number'   # Append this class to every td
        c.content do |article|                  # content for each td, passes the model for the
                                                # row into the block
          link_to article.comments.size, article_comments(article)
        end
      end

    end

This produces a very clean html table. See TableFor2's README for more examples and sample output.


        
        

