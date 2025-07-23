// Purpose: View Addresses, add more and update them

import 'package:flutter/material.dart';

class AddressCardData {
  final TextEditingController addressNameController;
  final TextEditingController addressLine1Controller;
  final TextEditingController addressLine2Controller;
  bool editing;

  AddressCardData({
    String name = '',
    String line1 = '',
    String line2 = '',
    this.editing = true
}) : addressNameController = TextEditingController(text: name),
     addressLine1Controller = TextEditingController(text: line1),
     addressLine2Controller = TextEditingController(text: line2);
  
}


class AddressScroller extends StatefulWidget {
  final Map<String, String> addressList;

  const AddressScroller({
    super.key,
    required this.addressList
});

  @override
  State<StatefulWidget> createState() {
    return AddressScrollerState();
  }
}


class AddressScrollerState extends State<AddressScroller> {
  final pageController = PageController(viewportFraction: 0.9);

  @override
  Widget build(BuildContext context) {

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Text("Saved Addresses", style: TextStyle(fontSize: 40),),
            Expanded(child: PageView.builder(
              controller: pageController,
              itemCount: widget.addressList.length,
              itemBuilder: (context, index) {
                final List<AddressCardData> addresses = widget.addressList.entries.map(
                        (item) => AddressCardData(name: item.name, line1: item.line1, line2: item.line2)
                ).toList();
                final currAddr = addresses[index];

                return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(currAddr.addressNameController.text, style: TextStyle(fontSize: 40)),
                            SizedBox(height: 12,),
                            Text(currAddr.addressLine1Controller.text, style: TextStyle(fontSize: 20),),
                            SizedBox(height: 5,),
                            Text(currAddr.addressLine2Controller.text, style: TextStyle(fontSize: 20),),
                            const Spacer(),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      currAddr.editing = !currAddr.editing;
                                    });
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: Text(currAddr.editing ? "Done" : "Edit"),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                );
              },
            )),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.add),
                  label: const Text("Add"),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}



extension on MapEntry<String, String> {
  get name => this.key;
  get line1 => this.value[0];
  get line2 => this.value[1];
}
