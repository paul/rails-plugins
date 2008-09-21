
# Rails Plugins

## Table For 2 -- `table_for2`

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

## Labeled-List Form Builder -- `ll_form_builder`

In rails 2.0, the form_for is rather inflexible, this may have changed in 2.1.0, I haven't checked. Rather than attemping to override all the `form_for` methods to support better markup for handling forms, I just copied them into a new module. It works almost exactly like the build-in `form_for`, but produces an ordered list of form fields with labels. 

    <ol>
      <li>
        <label for="title">Title:</label>
        <input type="text">
      </li>
    </ol>

See the readme for more samples and docs.


        

