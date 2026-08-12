/*
 * Record an element's reflow reads and class additions in call order, so specs
 * can assert that a reflow is forced before the transition class lands, or that
 * no reflow happens at all.
 *
 * Nothing tears the offsetHeight getter down afterward, so pass an element
 * created in the test's own setup rather than a long-lived one.
 */
global.recordTransitionOrder = (element) => {
  const order = [],
        originalAdd = element.classList.add.bind(element.classList);

  Object.defineProperty(element, "offsetHeight", {
    "configurable": true,
    "get": () => {
      order.push("reflow");

      return 0;
    }
  });

  sinon.stub(element.classList, "add").callsFake((...args) => {
    order.push(`add:${args.join(",")}`);

    return originalAdd(...args);
  });

  return order;
};
