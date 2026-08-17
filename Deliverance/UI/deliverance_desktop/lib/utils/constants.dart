String iconForType(String type) {
  switch (type) {
    case "Computer":
      return 'assets/icons/computer.svg';
    case "Laptop":
      return 'assets/icons/laptop.svg';
    case "Server":
      return 'assets/icons/server.svg';
    case "Projector":
      return 'assets/icons/projector.svg';
    case "Switch":
      return 'assets/icons/switch.svg';
    case "Router":
      return 'assets/icons/router.svg';
    default:
      return 'assets/icons/computer.svg';
  }
}
