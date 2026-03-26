import { LightningElement, track, api } from "lwc";
import ToastContainer from "lightning/toastContainer";
import Toast from "lightning/toast";
// Import Apex methods for proactive messaging functionality
import getProactiveSkills from "@salesforce/apex/Capitec_ProactiveMessagingController.getProactiveSkills";
import getProactiveTemplates from "@salesforce/apex/Capitec_ProactiveMessagingController.getProactiveTemplates";
import generateProactiveMessage from "@salesforce/apex/Capitec_ProactiveMessagingController.generateProactiveMessage";
import initiateProactiveMessage from "@salesforce/apex/Capitec_ProactiveMessagingController.initiateProactiveMessage";

export default class ProactiveMessagingInterface extends LightningElement {
  // Public properties passed from the parent component or page
  @api recordId; // Record ID of the case
  @api department; // Department for the proactive message
  @api teamName; // Team name for the proactive message
  @api priority; // Priority of the proactive message
  @api type; // Type of the proactive message
  @api outboundNumber; // Outbound number for the proactive message

  // Tracked properties for reactive UI updates
  @track proactiveSkillOptions = []; // Options for proactive skills dropdown
  @track proactiveTemplateOptions = []; // Options for proactive templates dropdown
  @track proactives = []; // List of proactive templates
  @track templateParameters = []; // Parameters for the proactive template
  @track selectedProactiveSkill; // Selected proactive skill
  @track selectedProactiveTemplate; // Selected proactive template
  @track selectedProactive; // Selected proactive template details
  @track selectedSkill; // Selected skill details
  @track processedProactiveMessage; // Processed proactive message content

  // Tracked properties for displaying client and agent details
  @track clientName; // Name of the client
  @track agentName; // Name of the agent
  @track agentPhotoUrl; // URL of the agent's photo
  @track currentDateTime; // Current date and time

  // Tracked properties for UI state management
  @track spinner; // Controls the visibility of the loading spinner
  @track isLoading; // Controls the loading state of the proactive templates dropdown

  @track proactiveMessage; // Proactive message content to display

  // Lifecycle hook called when the component is connected to the DOM
  async connectedCallback() {
    await this.initialize(); // Initialize the component

    // Configure the toast container for displaying notifications
    const toastContainer = ToastContainer.instance();
    toastContainer.maxShown = 5; // Maximum number of toasts to display
    toastContainer.toastPosition = "top-center"; // Position of the toasts
    toastContainer.containerPosition = "fixed"; // Container position
  }

  // Initialize the component by fetching proactive skills
  async initialize() {
    await this.fetchProactiveSkills();
  }

  // Event handler for proactive skill selection
  async handleSkillChange(event) {
    this.selectedProactiveSkill = event.detail.value; // Update selected skill
    this.selectedSkill = this.proactiveSkillOptions.find(skill => skill.value === this.selectedProactiveSkill);

    // Reset proactive template options and selection
    this.proactiveTemplateOptions = [];
    this.selectedProactiveTemplate = null;

    await this.fetchProactiveTemplates(); // Fetch templates for the selected skill
  }

  // Event handler for proactive template selection
  async handleProactiveChange(event) {
    this.selectedProactiveTemplate = event.detail.value; // Update selected template
    this.selectedProactive = this.proactives.find(proactive => proactive.proactiveId === this.selectedProactiveTemplate);

    if (this.selectedProactive) {
      await this.generateMessage(); // Generate the proactive message
    }
  }

  // Event handler for sending the proactive message
  async handSendMessage() {
    await this.initiateMessage(); // Initiate the proactive message
  }

  // Fetch proactive skills from the server
  async fetchProactiveSkills() {
    this.spinner = true; // Show loading spinner
    getProactiveSkills({ recordId: this.recordId })
      .then(result => {
        if (result.isSuccess && result.Data) {
          let data = JSON.parse(result.Data);

          // Update client and agent details
          this.clientName = data.clientName;
          this.agentName = data.agentName;
          this.agentPhotoUrl = data.agentPhotoUrl;
          this.currentDateTime = data.currentDateTime;

          // Map skills to dropdown options
          const profileSkills = data.profileSkillsWrapper.profileSkills;
          this.proactiveSkillOptions = profileSkills
            .flatMap(profile => profile.skills || [])
            .map(skill => ({
              label: skill.skillName, value: skill.skillId
            }));
        } else {
          console.log(JSON.stringify(result.Message));
          this.showToast("Error", result.Message, "error"); // Show error toast
        }
        this.spinner = false; // Hide loading spinner
      })
      .catch(error => {
        console.log(JSON.stringify(error));
        this.showToast("Error", JSON.stringify(error), "error"); // Show error toast
        this.spinner = false; // Hide loading spinner
      });
  }

  // Fetch proactive templates for the selected skill
  async fetchProactiveTemplates() {
    this.isLoading = true; // Show loading state for templates dropdown
    getProactiveTemplates({ skillId: this.selectedProactiveSkill })
      .then(result => {
        if (result.isSuccess && result.Data) {
          let data = JSON.parse(result.Data);
          this.proactives = data.proactives;

          // Map templates to dropdown options
          this.proactiveTemplateOptions = this.proactives.map(proactive => ({
            label: proactive.proactiveName, value: proactive.proactiveId
          }));
        } else {
          console.log(JSON.stringify(result.Message));
          this.showToast("Error", result.Message, "error"); // Show error toast
        }
        this.isLoading = false; // Hide loading state
      })
      .catch(error => {
        console.log(JSON.stringify(error));
        this.showToast("Error", JSON.stringify(error), "error"); // Show error toast
        this.isLoading = false; // Hide loading state
      });
  }

  // Generate the proactive message based on the selected template
  async generateMessage() {
    this.spinner = true; // Show loading spinner
    generateProactiveMessage({ recordId: this.recordId, proactiveTemplate: JSON.stringify(this.selectedProactive) })
      .then(result => {
        if (result.isSuccess && result.Data) {
          this.processedProactiveMessage = JSON.parse(result.Data);
          this.proactiveMessage = this.processedProactiveMessage.proactiveContent; // Update message content
          this.templateParameters = this.processedProactiveMessage.templateParameters; // Update template parameters
        } else {
          console.log(JSON.stringify(result.Message));
          this.showToast("Error", result.Message, "error"); // Show error toast
        }
        this.spinner = false; // Hide loading spinner
      })
      .catch(error => {
        console.log(JSON.stringify(error));
        this.showToast("Error", JSON.stringify(error), "error"); // Show error toast
        this.spinner = false; // Hide loading spinner
      });
  }

  // Initiate the proactive message by sending it to the server
  async initiateMessage() {
    this.spinner = true; // Show loading spinner

    // Prepare proactive message data
    const proactiveMessageData = {
      recordId: this.recordId,
      department: this.department,
      teamName: this.teamName,
      priority: Number(this.priority),
      type: this.type,
      outboundNumber: this.outboundNumber,
      skill: this.selectedSkill.label,
      skillId: this.selectedSkill.value,
      templateId: this.selectedProactive.proactiveId,
      templateParameters: this.templateParameters,
      proactiveMessage: this.proactiveMessage
    };

    initiateProactiveMessage({
      proactiveMessage: JSON.stringify(proactiveMessageData)
    })
      .then(result => {
        if (result.isSuccess) {
          this.showToast("Successful", result.Message, "success"); // Show success toast
        } else {
          console.log(JSON.stringify(result.Message));
          this.showToast("Error", result.Message, "error"); // Show error toast
        }
        this.spinner = false; // Hide loading spinner
      })
      .catch(error => {
        console.log(JSON.stringify(error));
        this.showToast("Error", JSON.stringify(error), "error"); // Show error toast
        this.spinner = false; // Hide loading spinner
      });
  }

  // Computed property to disable the send button if no skill or template is selected
  get buttonIsDisabled() {
    return this.selectedProactiveSkill === null
      || this.selectedProactiveSkill === undefined
      || this.selectedProactiveTemplate === null
      || this.selectedProactiveTemplate === undefined;
  }

  // Computed property to display a default message if no template is selected
  get proactiveDefaultMessage() {
    if (this.selectedProactiveTemplate === null
      || this.selectedProactiveTemplate === undefined) {
      this.proactiveMessage = `Please select a skill and template for the message preview.`;
    }
    return this.proactiveMessage;
  }

  // Helper method to display a toast notification
  showToast(title, message, variant) {
    Toast.show({
      label: title, message: message, mode: "dismissible", variant: variant
    }, this);
  }
}