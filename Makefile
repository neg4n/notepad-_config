NVIM ?= nvim

.PHONY: test
test:
	$(NVIM) --headless -u NONE -c "lua dofile('scripts/minitest.lua')" -c "qa"
