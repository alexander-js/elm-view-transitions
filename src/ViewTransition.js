export default class ElmViewTransition extends HTMLElement {
  static get observedAttributes() {
    return [
      "state"
    ]
  }

  get childNodes() {
    return this.proxy.childNodes
  }

  get replaceChild() {
    return this.proxy.replaceChild
  }

  get removeChild() {
    return this.proxy.removeChild
  }

  get insertBefore() {
    return this.proxy.insertBefore
  }

  get appendChild() {
    return this.proxy.appendChild
  }

  constructor() {
    super()

    const proxy = this.createDomNodeProxy({
      node: this,
      parent: this.parentElement,
    })

    this.deferredPatches = []
    this.proxy = new Proxy({}, {
      get: (target, prop, receiver) => {
        return proxy[prop]
      }
    })
  }

  applyPatches() {
    this.deferredPatches.forEach(patch => patch());
    this.deferredPatches = []
  }

  mutate(thunk) {
    if (this.pendingViewTransition) {
      this.startViewTransition(this.viewTransitions)
      this.pendingViewTransition = false
    }

    if (this.viewTransitions === null) {
      thunk()
    } else {
      this.deferredPatches.push(thunk)
    }
  }

  connectedCallback() {
    this.styleNode = this.createStyleNode()
    this.applyPatches()
  }

  createStyleNode() {
    const element = document.createElement("style")
    element.setAttribute("id", "view-transition-root-styles")
    document.head.appendChild(element)
    return element
  }

  /**
   * When a View Transition is in progress, we return our own-made up objects instead of the DOM nodes that Elm thinks it is receiving.
   * These objects have their own implementation of all the methods/setters that the Elm runtime uses to change the DOM.
   * By doing this, we can control **when** those changes happen.
   *
   * This is necessary in order to properly capture the "before" and "after" snapshots of the DOM.
   */
  createDomNodeProxy({ node, parent }) {
    const isRoot = node === this
    const replaceChild = isRoot ? super.replaceChild.bind(this) : node.replaceChild.bind(node)
    const removeChild = isRoot ? super.removeChild.bind(this) : node.removeChild.bind(node)
    const insertBefore = isRoot ? super.insertBefore.bind(this) : node.insertBefore.bind(node)
    const appendChild = isRoot ? super.appendChild.bind(this) : node.appendChild.bind(node)
    const childNodes = isRoot ? super.childNodes : node.childNodes

    let children

    const getChildren = () => {
      if (children) {
        return children
      }

      children = Array
        .from(childNodes)
        .map(child => {
          return this.createDomNodeProxy({
            node: child,
            parent: proxy
          })
        })

      return children
    }

    const proxy = new Proxy(node, {
      get: (target, prop) => {
        switch (prop) {
          case "__realNode__":
            return node;
            break;

          case "childNodes":
            return getChildren();
            break;

          case "parentNode":
            return parent;
            break;

          case "replaceData":
            return (...args) => {
              this.mutate(() => {
                node.replaceData(...args)
              })
            }
            break;

          case "replaceChild":
            return (newChild, oldChild) => {
              newChild = this.createDomNodeProxy({
                node: newChild,
                parent: proxy
              })

              getChildren().splice(getChildren().findIndex(el => el === oldChild), 1, newChild)

              this.mutate(() => {
                replaceChild(newChild.__realNode__, oldChild.__realNode__)
              })

              return oldChild
            };
            break;

          case "removeChild":
            return (child) => {
              getChildren().splice(getChildren().findIndex(el => el === child), 1)

              this.mutate(() => {
                removeChild(child.__realNode__)
              })

              return child
            };
            break;

          case "insertBefore":
            return (newNode, referenceNode) => {
              newNode = this.createDomNodeProxy({
                node: newNode,
                parent: proxy
              })

              // Elm sometimes passes `undefined` as referenceNode. This is an Elm bug.
              // See https://github.com/elm/virtual-dom/issues/161
              referenceNode = referenceNode || { __realNode__: null }

              const referenceNodeIndex = getChildren().findIndex(el => el.__realNode__ === referenceNode.__realNode__)

              getChildren().splice(referenceNodeIndex - 1, 0, newNode)

              this.mutate(() => {
                insertBefore(newNode.__realNode__, referenceNode.__realNode__)
              })

              return newNode
            };
            break;

          case "appendChild":
            return (child) => {
              const proxyChild = this.createDomNodeProxy({
                node: child,
                parent: proxy
              })

              getChildren().push(proxyChild)

              this.mutate(() => {
                appendChild(proxyChild.__realNode__)
              })

              return child
            };
            break;

          case "setAttribute":
            return (key, value) => {
              this.mutate(() => node.setAttribute(key, value))
            };
            break;

          case "removeAttribute":
            return (key) => {
              this.mutate(() => node.removeAttribute(key))
            };
            break;

          case "style":
            return new Proxy(node.style, {
              set: (target, key, value) => {
                this.mutate(() => {
                  target[key] = value
                })

                return value;
              }
            })
            break;

          // addEventListener, removeEventListener, elm_event_node_ref, etc...
          default:
            const value = node[prop]

            if (typeof value === "function") {
              return value.bind(node)
            }

            return value
            break;
        }
      },

      set: (target, key, value) => {
        this.mutate(() => {
          node[key] = value
        });

        return true;
      }
    })

    return proxy
  }

  startViewTransition(viewTransitions) {
    this.styleNode.textContent = viewTransitions.map(({ id, name }) => {
      return `
        #${id} {
          view-transition-name: ${name};
        }
      `
    }).join("\n")

    const transition = document.startViewTransition(() => {
      this.applyPatches()
      this.dispatchEvent(new CustomEvent("elm-view-transition-finish"))
    })

    transition.finished.then(() => {
      this.styleNode.textContent = ""
    })
  }

  attributeChangedCallback(name, oldValue, newValue) {
    if (name === "state") {
      this.viewTransitions = JSON.parse(newValue)

      if (this.viewTransitions !== null) {
        this.pendingViewTransition = true
      }
    }
  }
}