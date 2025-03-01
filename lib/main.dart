import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

// Widget principal de la app.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conversor de Monedas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
      routes: {
        '/history': (context) => HistoryScreen(),
      },
    );
  }
}

// Pantalla principal: Conversión de monedas.
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _baseCurrency = 'EUR';
  String _targetCurrency = 'USD';
  DateTime? _selectedDate;
  String _result = '';

  // Lista de monedas disponibles.
  final List<String> currencies = ['EUR', 'USD', 'GBP', 'JPY', 'AUD', 'CAD', 'CHF'];

  // Función para seleccionar fecha mediante un DatePicker.
  Future<void> _pickDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1999),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  // Función para llamar a la API de Frankfurter y realizar la conversión.
  Future<void> _convertCurrency() async {
    String amountText = _amountController.text;
    if (amountText.isEmpty) return;
    double amount = double.tryParse(amountText) ?? 0;
    String url;
    if (_selectedDate != null) {
      String formattedDate =
          "${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
      url = 'https://api.frankfurter.app/$formattedDate?amount=$amount&from=$_baseCurrency&to=$_targetCurrency';
    } else {
      url = 'https://api.frankfurter.app/latest?amount=$amount&from=$_baseCurrency&to=$_targetCurrency';
    }

    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _result = data['rates'][_targetCurrency].toString();
        });
      } else {
        setState(() {
          _result = 'Error en la conversión';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conversor de Monedas'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/history');
            },
          ),
        ],
      ),
      // Se utiliza LayoutBuilder y ConstrainedBox para asegurar límites en la altura.
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Campo para ingresar la cantidad a convertir.
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Cantidad',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Fila con dos Dropdowns para seleccionar las monedas.
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _baseCurrency,
                            decoration: InputDecoration(
                              labelText: 'Moneda Base',
                              border: OutlineInputBorder(),
                            ),
                            items: currencies.map((String currency) {
                              return DropdownMenuItem(
                                value: currency,
                                child: Text(currency),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _baseCurrency = value!;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _targetCurrency,
                            decoration: InputDecoration(
                              labelText: 'Moneda Destino',
                              border: OutlineInputBorder(),
                            ),
                            items: currencies.map((String currency) {
                              return DropdownMenuItem(
                                value: currency,
                                child: Text(currency),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _targetCurrency = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Botones para seleccionar la fecha y ejecutar la conversión.
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickDate,
                            child: Text(_selectedDate == null
                                ? 'Selecciona una fecha'
                                : '${_selectedDate!.toLocal()}'.split(' ')[0]),
                          ),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _convertCurrency,
                          child: Text('Convertir'),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    // Resultado dentro de una tarjeta minimalista y centralizada.
                    Center(
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Resultado: $_result',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Pantalla de Historia: Visualiza las tasas de cambio recientes.
class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _baseCurrency = 'EUR';
  List<dynamic> _ratesList = [];
  bool _isLoading = false;

  final List<String> currencies = ['EUR', 'USD', 'GBP', 'JPY', 'AUD', 'CAD', 'CHF'];

  // Función para obtener las tasas de cambio de la API.
  Future<void> _fetchRates() async {
    setState(() {
      _isLoading = true;
    });
    String url = 'https://api.frankfurter.app/latest?from=$_baseCurrency';
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        List<dynamic> rates = [];
        data['rates'].forEach((key, value) {
          rates.add({'currency': key, 'rate': value});
        });
        setState(() {
          _ratesList = rates;
          _isLoading = false;
        });
      } else {
        setState(() {
          _ratesList = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _ratesList = [];
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchRates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Tasas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Selección de moneda base para actualizar las tasas.
            DropdownButtonFormField<String>(
              value: _baseCurrency,
              decoration: InputDecoration(
                labelText: 'Moneda Base',
                border: OutlineInputBorder(),
              ),
              items: currencies.map((String currency) {
                return DropdownMenuItem(
                  value: currency,
                  child: Text(currency),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _baseCurrency = value!;
                });
                _fetchRates();
              },
            ),
            SizedBox(height: 16),
            // Lista de tasas de cambio.
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _ratesList.length,
                      itemBuilder: (context, index) {
                        var rateItem = _ratesList[index];
                        return ListTile(
                          title: Text('${rateItem['currency']}'),
                          trailing: Text(rateItem['rate'].toString()),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
