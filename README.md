This is a complete, updated epub3 module for hugo. It was born out of necessity, I didn't know much about hugo, scripting, makefiles, github etc, but I stuck to it and learnt. It passes all verification, from the official epub3 checker to calibre's stringent style checks.

Now how to use it:

Linking to chapters is not automatic, but it suffices to add {#name-for-addressing} as a markdown attribute to the level1 header and write links simply [something](#name-for-addressing). Perl just gives the chapter file the name chosen.
to include images, drop them under assets/images and write ![something](filename.ext)
front and backcovers have the same format, just drop them and indicate them in the book's frontmatter
	frontCoverImages: [{filename: ""}, {filename: "", caption: ""}]
	backCoverImages: [{filename: ""}, {filename: ""}]
	They are not mandatory.
Chapters are automatically counted. No standalone table of content is created, readers create their own.
Just drop fonts under static/EPUB/fonts. Since hugo can't use Go facilities to extract font info, I added a script. Only dependency: fontconfig. The make script takes care of it. Naturally, you should inspect the family name obtained under data/fonts.yaml in order to use in css.
Overall, you just write your book in a single book.md at the root and let the module do the magic ;-)
Yet to implement: links to ids inside chapters.