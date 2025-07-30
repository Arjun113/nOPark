// Purpose: the "Where to next?" location picker

import 'package:flutter/material.dart';
import 'package:nopark/features/profiles/presentation/widgets/address_scroller.dart';

class WhereToNextWidget extends StatefulWidget {
  final void Function(String) onAddressSelected;
  final List<AddressCardData> addresses;
  final String userName;
  final String profileURL;

  const WhereToNextWidget({
    super.key,
    required this.userName,
    required this.profileURL,
    required this.addresses,
    required this.onAddressSelected,
  });

  @override
  State<WhereToNextWidget> createState() => _WhereToNextWidgetState();
}

class _WhereToNextWidgetState extends State<WhereToNextWidget> {
  bool isExpanded = false;
  bool isInputMode = false;
  final TextEditingController _controller = TextEditingController();
  final List<String> defaultSuggestions = [
    'Clayton',
    'Caulfield',
    'Peninsula',
    'Law Chambers',
  ];

  void toggleExpansion() {
    setState(() {
      if (!isExpanded) {
        isExpanded = true;
      } else {
        isInputMode = true;
      }
    });
  }

  void onSelectAddress(String address) {
    widget.onAddressSelected(address);
    setState(() {
      _controller.text = address;
      isInputMode = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {}); // rebuilds on text change to toggle fade
    });
  }

  Widget buildCollapsed() {
    return GestureDetector(
      onTap: toggleExpansion,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black12)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.location_on),
            SizedBox(width: 10),
            Text("Where to next?", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget buildExpanded() {
    final isTyping = _controller.text.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black12)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting + Avatar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hello${widget.userName}!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              CircleAvatar(
                backgroundImage: NetworkImage(
                  widget.profileURL,
                ), // update as needed
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Input field
          GestureDetector(
            onTap: toggleExpansion,
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Enter destination',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              onSubmitted: widget.onAddressSelected,
            ),
          ),
          const SizedBox(height: 12),

          // Animated switch between suggestions and autocomplete
          AnimatedCrossFade(
            firstChild: buildSuggestions(),
            secondChild: buildAutocompletePlaceholder(),
            crossFadeState:
                isTyping ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget buildSuggestions() {
    return Column(
      children:
          defaultSuggestions
              .map(
                (s) => GestureDetector(
                  onTap: () => onSelectAddress(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s, style: const TextStyle(fontSize: 16)),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  // NOTE: This will be replaced by Maps integration
  Widget buildAutocompletePlaceholder() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.place_outlined),
              const SizedBox(width: 10),
              Text(
                "Autocomplete result ${index + 1}",
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isExpanded ? buildExpanded() : buildCollapsed(),
    );
  }
}
