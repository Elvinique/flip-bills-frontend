import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FlightSeatGrid extends StatefulWidget {
  final List<int> occupiedSeats;
  final ValueChanged<List<int>> onSeatsChanged;
  final int totalRows;
  final int seatsPerRow; // usually 4 or 6 (e.g. 3-3 or 2-2)

  const FlightSeatGrid({
    super.key,
    required this.occupiedSeats,
    required this.onSeatsChanged,
    this.totalRows = 6,
    this.seatsPerRow = 4,
  });

  @override
  State<FlightSeatGrid> createState() => _FlightSeatGridState();
}

class _FlightSeatGridState extends State<FlightSeatGrid> {
  final List<int> _selectedSeats = [];

  void _toggleSeat(int seatIndex) {
    if (widget.occupiedSeats.contains(seatIndex)) return;

    setState(() {
      if (_selectedSeats.contains(seatIndex)) {
        _selectedSeats.remove(seatIndex);
      } else {
        _selectedSeats.add(seatIndex);
      }
    });
    widget.onSeatsChanged(_selectedSeats);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.totalRows,
        itemBuilder: (context, rowIndex) {
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.seatsPerRow + 1, (colIndex) {
                // Add an aisle in the middle
                if (colIndex == widget.seatsPerRow ~/ 2) {
                  return const SizedBox(height: 24, width: 24, child: Center(child: Text("")));
                }
                
                final actualCol = colIndex > widget.seatsPerRow ~/ 2 ? colIndex - 1 : colIndex;
                final seatIndex = rowIndex * widget.seatsPerRow + actualCol;
                
                final isOccupied = widget.occupiedSeats.contains(seatIndex);
                final isSelected = _selectedSeats.contains(seatIndex);
                
                // Flight seat labeling: Row number + Letter
                final rowLabel = (rowIndex + 1).toString();
                final colLabel = String.fromCharCode(65 + actualCol); // A, B, C...
                final seatLabel = "$rowLabel$colLabel";

                return GestureDetector(
                  onTap: () => _toggleSeat(seatIndex),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isOccupied
                          ? Colors.grey.shade300
                          : isSelected
                              ? const Color(0xff0b845c)
                              : const Color(0xffe8f5f0),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                      border: Border.all(
                        color: isOccupied
                            ? Colors.grey.shade400
                            : isSelected
                                ? const Color(0xff0b845c)
                                : const Color(0xff0b845c).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        seatLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isOccupied
                              ? Colors.grey.shade500
                              : isSelected
                                  ? Colors.white
                                  : const Color(0xff0b845c),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
