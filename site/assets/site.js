(() => {
  const ui = JSON.parse(document.getElementById("site-ui").textContent);
  const status = document.getElementById("site-status");
  const root = new URL(document.body.dataset.root || "./", window.location.href);
  const theme = document.querySelector(".theme-select");
  theme.value = document.documentElement.dataset.themePreference;
  theme.addEventListener("change", () => {
    window.dispatchEvent(new CustomEvent("hve-theme-change", { detail: theme.value }));
    try {
      localStorage.setItem("hve-docs-theme", theme.value);
    } catch (error) {
      status.textContent = ui.themeStorageError;
      console.warn("Could not save the theme preference.", error);
    }
  });
  document.querySelector(".locale-select").addEventListener("change", event => {
    const destination = new URL(event.target.value, window.location.href);
    destination.hash = window.location.hash;
    window.location.assign(destination.href);
  });

  const mobileMenu = document.querySelector(".mobile-navigation");
  const mobileSummary = mobileMenu.querySelector("summary");
  const closeMenu = () => { mobileMenu.open = false; };
  mobileMenu.querySelectorAll("a").forEach(link => link.addEventListener("click", closeMenu));
  document.addEventListener("click", event => {
    if (mobileMenu.open && !mobileMenu.contains(event.target)) closeMenu();
  });
  document.addEventListener("keydown", event => {
    if (event.key === "Escape" && mobileMenu.open) {
      closeMenu();
      mobileSummary.focus();
    }
  });
  window.matchMedia("(min-width: 1001px)").addEventListener("change", event => {
    if (event.matches) closeMenu();
  });
  document.querySelectorAll(".mobile-toc a").forEach(link => {
    link.addEventListener("click", () => { link.closest("details").open = false; });
  });

  document.querySelectorAll("[data-copy-target]").forEach(button => {
    let reset;
    button.addEventListener("click", async () => {
      clearTimeout(reset);
      const block = document.getElementById(button.dataset.copyTarget);
      const code = block.querySelector("code") || block;
      try {
        if (!navigator.clipboard) throw new Error("Clipboard API is unavailable.");
        await navigator.clipboard.writeText(code.textContent);
        button.textContent = ui.copied;
        button.removeAttribute("title");
        status.textContent = ui.copied;
        reset = setTimeout(() => { button.textContent = ui.copy; }, 1800);
      } catch (error) {
        button.textContent = ui.copyFailed;
        button.title = ui.copyError;
        status.textContent = ui.copyError;
        const range = document.createRange();
        range.selectNodeContents(code);
        const selection = window.getSelection();
        selection.removeAllRanges();
        selection.addRange(range);
        console.warn("Could not copy code.", error);
      }
    });
  });

  const tocLinks = [...document.querySelectorAll(".toc-link")];
  const tocTargets = new Set(tocLinks.map(link => link.hash));
  const headings = [...document.querySelectorAll(".doc-content h2[id], .doc-content h3[id]")]
    .filter(heading => tocTargets.has(`#${heading.id}`));
  let scheduled = false;
  function updateCurrentSection() {
    const headerBottom = document.querySelector(".site-header").getBoundingClientRect().bottom + 32;
    let active = headings[0];
    for (const heading of headings) {
      if (heading.getBoundingClientRect().top > headerBottom) break;
      active = heading;
    }
    for (const link of tocLinks) {
      if (active && link.hash === `#${active.id}`) link.setAttribute("aria-current", "location");
      else link.removeAttribute("aria-current");
    }
    scheduled = false;
  }
  window.addEventListener("scroll", () => {
    if (!scheduled) {
      scheduled = true;
      requestAnimationFrame(updateCurrentSection);
    }
  }, { passive: true });
  updateCurrentSection();

  const dialog = document.querySelector(".search-dialog");
  const searchState = dialog.querySelector(".search-state");
  const searchTrigger = document.querySelector(".search-trigger");
  let searchReady = false;
  let searchLoading;
  let lastFocus;
  async function loadSearch() {
    if (searchReady) return;
    if (searchLoading) return searchLoading;
    searchState.hidden = false;
    searchState.textContent = ui.searchLoading;
    searchLoading = (async () => {
      if (!window.PagefindUI) {
        if (!document.querySelector("[data-search-styles]")) {
          const style = document.createElement("link");
          style.rel = "stylesheet";
          style.href = new URL("pagefind/pagefind-ui.css", root);
          style.dataset.searchStyles = "";
          document.head.prepend(style);
        }
        await new Promise((resolve, reject) => {
          const script = document.createElement("script");
          script.src = new URL("pagefind/pagefind-ui.js", root);
          script.onload = resolve;
          script.onerror = () => { script.remove(); reject(new Error("Pagefind UI could not load.")); };
          document.head.append(script);
        });
      }
      new window.PagefindUI({
        element: "#search-results",
        bundlePath: new URL("pagefind/", root).pathname,
        baseUrl: root.pathname,
        showSubResults: true,
        showImages: false,
        resetStyles: false,
        translations: ui.searchTranslations,
      });
      searchReady = true;
      searchState.hidden = true;
    })();
    try {
      await searchLoading;
    } finally {
      searchLoading = undefined;
    }
  }
  async function openSearch() {
    if (dialog.open) return;
    closeMenu();
    lastFocus = document.activeElement;
    dialog.showModal();
    try {
      await loadSearch();
      if (dialog.open) dialog.querySelector("input")?.focus();
    } catch (error) {
      searchState.hidden = false;
      searchState.textContent = ui.searchError;
      console.error("Documentation search is unavailable.", error);
    }
  }
  searchTrigger.addEventListener("click", openSearch);
  dialog.querySelector(".search-close").addEventListener("click", () => dialog.close());
  dialog.addEventListener("click", event => {
    const bounds = dialog.getBoundingClientRect();
    if (event.target === dialog && (event.clientX < bounds.left || event.clientX > bounds.right || event.clientY < bounds.top || event.clientY > bounds.bottom)) dialog.close();
  });
  dialog.addEventListener("close", () => lastFocus?.focus());
  document.addEventListener("keydown", event => {
    const target = event.target;
    const typing = target instanceof HTMLElement && (target.isContentEditable || ["INPUT", "TEXTAREA", "SELECT"].includes(target.tagName));
    if (!typing && (event.key === "/" || ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === "k"))) {
      event.preventDefault();
      openSearch();
    }
  });
})();
