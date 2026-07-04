# frozen_string_literal: true

require "rails_helper"

describe "shared/_dialog.html.erb" do
  subject(:html) do
    render partial: "shared/dialog",
           locals:  { id: id, dismissable: dismissable }

    rendered
  end

  let(:dismissable) { false }
  let(:id)          { "category_dialog" }

  it "renders the dialog controller wrapper" do
    expect(html).to have_css("div[data-controller='dialog']", visible: :all)
  end

  it "renders the modal with the derived id" do
    expect(html).to have_css("dialog.dialog#category_dialog_modal", visible: :all)
  end

  it "labels the modal with the derived title id" do
    expect(html).to have_css("dialog[aria-labelledby='category_dialog_title']", visible: :all)
  end

  it "targets the dialog controller" do
    expect(html).to have_css("dialog[data-dialog-target='dialog']", visible: :all)
  end

  it "binds the backdrop and cancel actions" do
    expect(html).to have_css(
      "dialog[data-action='click->dialog#backdropClose cancel->dialog#cancel']",
      visible: :all
    )
  end

  it "renders the turbo frame" do
    expect(html).to have_css(
      "dialog turbo-frame#category_dialog[data-action='turbo:frame-load->dialog#open']",
      visible: :all
    )
  end

  context "when not dismissable" do
    it "omits the close action from the wrapper" do
      expect(html).to have_no_css("div[data-action='dialog:close->dialog#close']", visible: :all)
    end
  end

  context "when dismissable" do
    let(:dismissable) { true }

    it "binds the close action on the wrapper" do
      expect(html).to have_css("div[data-action='dialog:close->dialog#close']", visible: :all)
    end
  end
end
