const transition = (rootNode) => {
  if (!document.startViewTransition) return

  // Snapshot the old DOM before Elm patches it
  const clone = rootNode.cloneNode(true)
  clone.setAttribute("aria-hidden", "true")

  const originalDisplay = rootNode.style.display

  // Hide real DOM, show clone in its place
  rootNode.style.display = "none"
  rootNode.parentNode.insertBefore(clone, rootNode)

  // After Elm patches the real DOM (next frame), start the transition
  requestAnimationFrame(() => {
    document.startViewTransition(() => {
      clone.remove()
      rootNode.style.display = originalDisplay || null
    })
  })
};

export const ElmViewTransition = {
  init(app, rootNode) {
    app.ports.viewTransition_start.subscribe(() => transition(rootNode))
  }
};
