import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BusSeatGrid extends StatefulWidget {
  final int totalRows;
  final int seatsPerRow;
  final List<int> occupiedSeats;
  final Function(List<int>) onSeatsChanged;

  const BusSeatGrid({
    super.key,
    required this.totalRows,
    required this.seatsPerRow,
    required this.occupiedSeats,
    required this.onSeatsChanged,
  });

  @override
  State<BusSeatGrid> createState() => _BusSeatGridState();
}

class _BusSeatGridState extends State<BusSeatGrid> {
  final List<int> _selectedSeats = [];

  void _toggleSeatSelection(int seatIndex) {
    if (widget.occupiedSeats.contains(seatIndex)) return; // Prevents double-booking edge case

    setState(() {
      if (_selectedSeats.contains(seatIndex)) {
        _selectedSeats.remove(seatIndex);
      } else {
        _selectedSeats.add(seatIndex);
      }
    });
    // Stream updates directly back to parent state loop
    widget.onSeatsChanged(_selectedSeats);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildLegendIndicators(),
        const SizedBox(height: 24),
        _buildDriverCabBoundary(),
        const SizedBox(height: 16),
        
        // Dynamic Seat Selection Matrix
        Expanded(
          child: ListView.builder(
            itemCount: widget.totalRows,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, rowIndex) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(widget.seatsPerRow + 1, (colIndex) {
                    // Inject structural central aisle path mapping
                    if (colIndex == (widget.seatsPerRow / 2).floor()) {
                      return const SizedBox(width: 40);
                    }

                    // Re-calculate column offset mapping ignoring the walking aisle
                    final actualColIndex = colIndex > (widget.seatsPerRow / 2).floor() ? colIndex - 1 : colIndex;
                    final seatIndex = (rowIndex * widget.seatsPerRow) + actualColIndex + 1;

                    final isOccupied = widget.occupiedSeats.contains(seatIndex);
                    final isSelected = _selectedSeats.contains(seatIndex);

                    return _buildInteractiveSeatFrame(seatIndex, isOccupied, isSelected);
                  }),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLegendIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _legendItem("Available", const Color(0xffe6f3ef), const Color(0xff0b845c)),
        _legendItem("Selected", const Color(0xff0b845c), const Color(0xff086345)),
        _legendItem("Occupied", const Color(0xffe9ecef), const Color(0xffced4da)),
      ],
    );
  }

  Widget _legendItem(String label, Color bg, Color border) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xff495057))),
      ],
    );
  }

  Widget _buildDriverCabBoundary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xfff1f3f5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffe9ecef)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "FRONT / DRIVER CABIN",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xff6c757d),
              letterSpacing: 0.5,
            ),
          ),
          const Icon(Icons.incomplete_circle_rounded, color: Color(0xff495057), size: 22),
        ],
      ),
    );
  }

  Widget _buildInteractiveSeatFrame(int seatIndex, bool isOccupied, bool isSelected) {
    Color itemBg = const Color(0xffe6f3ef);
    Color itemBorder = const Color(0xff0b845c);
    Widget labelWidget = Text(
      '$seatIndex',
      style: TextStyle(fontWeight: FontWeight.w700, color: const Color(0xff0b845c), fontSize: 13),
    );

    if (isOccupied) {
      itemBg = const Color(0xffe9ecef);
      itemBorder = const Color(0xffced4da);
      labelWidget = const Icon(Icons.close_rounded, size: 16, color: Color(0xff6c757d));
    } else if (isSelected) {
      itemBg = const Color(0xff0b845c);
      itemBorder = const Color(0xff086345);
      labelWidget = Text(
        '$seatIndex',
        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
      );
    }

    return GestureDetector(
      onTap: () => _toggleSeatSelection(seatIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: itemBg,
          border: Border.all(color: itemBorder, width: 2),
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected 
  ? [BoxShadow(color: const Color(0xff0b845c).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 4))] 
  : null,
        ),
        alignment: Alignment.center,
        child: labelWidget,
      ),
    );
  }
}