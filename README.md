mt-layout-slot
==============

Movable Type plugin to enable layout and slot style template writing.

# Getting Started

Create a new template module named 'BasicLayout' to use as a layout.

<pre><code>&lt;html&gt;
&lt;head&gt;
&lt;title&gt;&lt;mt:Slot name="head_title" append=" | " desc="Document Title"&gt;My Blog&lt;/mt:Slot&gt;&lt;/title&gt;
&lt;/head&gt;
&lt;body&gt;
  &lt;mt:Slot name="html_body" desc="Document Body"&gt;&lt;/mt:Slot&gt;
  &lt;mt:Slot name="html_footer" desc="Document Footer"&gt;&amp;copy; ideaman's Inc.&lt;/mt:Slot&gt;
&lt;/body&gt;
&lt;/html&gt;
</code></pre>

Then create a new index template to use this layout.

<pre><code>&lt;mt:Layout module="BasicLayout"&gt;
&lt;mt:Slot name="head_title"&gt;Top Page&lt;/mt:Slot&gt;

&lt;mt:Slot name="html_body"&gt;
  Here is body.
&lt;/mt:Slot&gt;
&lt;/mt:Layout&gt;
</code></pre>

The result of the index template is like this.

<pre><code>&lt;html&gt;
&lt;head&gt;
&lt;title&gt;top Page | My Blog&lt;/title&gt;
&lt;/head&gt;
&lt;body&gt;
  Here is body.
  &copy; ideaman's Inc.
&lt;/body&gt;
&lt;/html&gt;
</code></pre>

If you use mt:Slot in mt:Layout, original mt:Slot tags in layout module will be replaced by name.

To use content of original slot, skip to write mt:Slot tag in mt:Layout.

You can use append or prepend modifier to retain the original content as sufix or prefix.

# Tags

## &lt;mt:Slot&gt;&lt;/mt:Slot&gt;

Defines of replace partial. If used in mt:Layout, the original slot is replaced. Or not in mt:Layout, defines a alot.

### name

Required to name the slot.

### append

In definition, the original content is appended to replaced content.

In mt:Layout, the new content is appended to original content.

Set a string to glue them.

### prepend

In definition, the original content is prepended to replaced content.

In mt:Layout, the new content is prepended to original content.

Set a string to glue them.

### trim

Trim white spaces on both of the sides of content.

Default is 1(true). Set 0 or empty not to trim.

## &lt;mt:Layout&gt;&lt;/mt:Layout&gt;

Use a module or file as layout.

Modifiers are compatible with mt:Include tag.

## &lt;mt:SlotHeader&gt;&lt;/mt:SlotHeader&gt; and &lt;mt:SlotFooter&gt;&lt;/mt:SlotFooter&gt;

Use in mt:Slot tag to define header and footer of the slot.

If the contents of the slot is not empty, they will be displayed.
