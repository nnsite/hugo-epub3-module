NAME := EBOOK
HUGO_ENVIRONMENT ?= preview
GIT_REPO ?= .
.ONESHELL:
.DELETE_ON_ERROR:
ifeq ($(HUGO_ENVIRONMENT),production)
PUBLIC := public
BOOK := ebook.epub
else
PUBLIC := public-preview
BOOK := ebook-preview.epub
endif
CONTENT := content
EPUBDIR := $(PUBLIC)/EPUB
SPLIT_STAMP := $(CONTENT)/.stamp
ARCHIVE := ../../archives/$(NAME)-HUGO.tar.zst
DEPLOY_STAMP := $(GIT_REPO)/.stamp-deploy

SOURCES := $(wildcard \
	book.md \
	perl_splitting \
	Makefile \
	hugo.yaml \
	assets/* assets/**/* \
	data/* data/**/* \
	i18n/**/* \
	layouts/* layouts/**/* \
	static/* static/**/*)

.PHONY: split preview production archive deploy check-epub clean

###############################################################################
# Split manuscript into Hugo content

$(SPLIT_STAMP): book.md perl_splitting
	rm -rf $(CONTENT)
	mkdir -p $(CONTENT)
	./perl_splitting $< $(CONTENT) || \
		(notify-send -e -u critical "$(NAME): split failed"; exit 1)
	touch $@

split: $(SPLIT_STAMP)

###############################################################################
# Build Hugo output arranged for EPUB

$(EPUBDIR): static/EPUB/fonts $(SPLIT_STAMP) $(SOURCES)
	hugo \
		--minify \
		--cleanDestinationDir \
		--destination $(PUBLIC) \
		--environment $(HUGO_ENVIRONMENT) \
		2>/tmp/hugo.log || \
		(notify-send -e -u critical "$(NAME): Hugo failed" \
			"$$(grep '^ERROR' /tmp/hugo.log)"; exit 1)
	rsync -a --delete \
		--exclude=EPUB/ \
		--exclude=mimetype \
		--exclude=META-INF/ \
		$(PUBLIC)/ $(EPUBDIR) || \
		(notify-send -e -u critical "$(NAME): rsync failed"; exit 1)
	rmdir $(PUBLIC)/* >/dev/null 2>&1 || true
	sed -Ei 's#(href|src|url)=(")?/#\1=\2#g' \
		$(EPUBDIR)/*.xhtml \
		$(EPUBDIR)/package.opf \
		$(EPUBDIR)/css/epub.css

###############################################################################
# Build EPUB

$(BOOK): $(EPUBDIR)
	cd $(PUBLIC)
	zip -X0 ../$@ mimetype
	zip -rX ../$@ EPUB META-INF || \
		(notify-send -e -u critical "$(NAME): zip failed"; exit 1)
	notify-send -u low -e "$(NAME): ebook created"

###############################################################################
# Preview

preview: $(BOOK)
	open $<

###############################################################################
# Production build

production:
	$(MAKE) preview HUGO_ENVIRONMENT=production

###############################################################################
# Validate EPUB

check-epub: $(BOOK)
	epubcheck $<

###############################################################################
# Archive project

$(ARCHIVE): $(BOOK)
	mkdir -p $(dir $@)
	tar --zstd -cf $@ \
		--exclude='ebook*' \
		--exclude='public*' \
		--exclude='resources' \
		.
	notify-send -u low -e "$(NAME): archive created"

archive: $(ARCHIVE)

###############################################################################
# Deploy

$(DEPLOY_STAMP): $(SOURCES) $(GIT_REPO)
	cd $(GIT_REPO)
	git add .
	git commit -m "update site" || true
	git push || {
		notify-send -u critical -e "$(NAME): Deploy FAILED"
		exit $$?
	}
	notify-send -u low -e "$(NAME): Deploy OK"
	touch $@

deploy: $(DEPLOY_STAMP)

###############################################################################
# Cleanup

clean:
	rm -rf $(CONTENT) public* ebook* resources*