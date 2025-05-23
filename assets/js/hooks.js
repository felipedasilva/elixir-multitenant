/**
 * @type {import("phoenix_live_view").HooksOptions}
 */
export let Hooks = {};

Hooks.FormatDate = {
  formatDate() {
    const formatter = new Intl.DateTimeFormat("en-GB", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      timeZone: "UTC",
    });

    this.el.innerText = formatter.format(new Date(this.el.dataset.date));
  },
  mounted() {
    this.formatDate();
  },
  updated() {
    this.formatDate();
  },
};

export default Hooks;
